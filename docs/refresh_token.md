# Managing OAuth Tokens for Blogger API v3

Based on the
[Google Cloud documentation](https://support.google.com/cloud/answer/15549257)
and standard OAuth 2.0 protocols for the Blogger API v3, here is
a summary of best practices for managing OAuth tokens when
publishing to Blogger:

## 1. What is the recommended way to manage an OAuth token for publishing to Blogger?

The recommended method for a script or application publishing to
a Blogger blog is to use **OAuth 2.0 with Offline Access**.

* **Use a Refresh Token:** Since you likely want to publish
  without manually logging in every time, you must request
  "offline access" during the initial authorisation. This grants
  you a **Refresh Token** alongside the short-lived Access Token.
* **Client Secret Management:** As detailed in the
  [Google Cloud documentation](https://support.google.com/cloud/answer/15549257),
  if your app type (e.g., Web Server) uses a Client Secret, you
  should treat it like a password. Do not hardcode it in public
  repositories. If you suspect a leak, use the
  **Rotate Client Secret** workflow described in the link to
  generate a new secret, update your application, and then
  disable the old one to maintain security without downtime.
* **Avoid Service Accounts:** Unlike other Google APIs, the
  Blogger API often has limitations or complexities with Service
  Accounts. It is generally smoother to use a standard OAuth
  client ID authorised by the Google Account that
  owns/administers the blog.

## 2. What is the lifetime of an OAuth token?

The **Access Token** (used to authenticate the actual API
request) has a lifetime of **1 hour (3,600 seconds)**.

Once this hour passes, the token becomes invalid, and your
application must use the Refresh Token to request a new Access
Token.

## 3. What is the lifetime of a refresh token?

A **Refresh Token** is generally **long-lived (indefinite)**,
meaning it does not expire by itself. However, it *will* stop
working under these specific conditions:

* **7 Days (Testing Mode):** If your Google Cloud Project's
  OAuth consent screen is set to "Testing" (and the user is an
  "External" user), the refresh token will expire strictly after
  7 days. You must move the app to "Production" status to get
  indefinite tokens.
* **6 Months of Inactivity:** If the refresh token has not been
  used to get a new access token for 6 months.
* **Password Change:** If the user changes their password and
  the refresh token contains Gmail scopes.
* **Revocation:** The user manually revokes access to your app
  in their Google Account security settings.
* **Token Limits:** There is a limit of **100** refresh tokens
  per Google Account per OAuth 2.0 client ID. If you exceed
  this limit, the oldest refresh token is automatically
  invalidated without warning.

## 4. Step-by-Step Guide

This guide assumes you are building a script (e.g., Python, R,
or a simple tool) to publish HTML content.

### **Phase 1: Google Cloud Console Setup**

1. **Create a Project:** Go to the
   [Google Cloud Console](https://console.cloud.google.com/) and
   create a new project.

2. **Enable API:** Navigate to **APIs & Services > Library**,
   search for "Blogger API v3", and enable it.

3. **Configure Consent Screen:**

   * Go to
     [Google Auth Platform > Audience](https://console.cloud.google.com/auth/audience).
   * Choose **External** (unless you are a Google Workspace user
     publishing only to your organisation).
   * **Crucial:** Set the status to **Production** (even if you
     are the only user) to avoid the 7-day token expiration. To
     set status to Production, you must
     [publish the application](https://console.cloud.google.com/auth/audience).

4. **Create Credentials:**

   * Go to
     [Google Auth Platform > Clients](https://console.developers.google.com/auth/clients).
   * Click **Create Client**.
   * **Application Type:** Choose **Desktop App** (e.g., for a
     script running on your machine) or **Web Application** (if
     you have a server).
   * **Important:** The client secret is only shown once at
     creation time. Copy and store it securely (e.g., in
     [Google Cloud Secret Manager](https://cloud.google.com/secret-manager/docs/overview)).
     Note the **Client ID** and **Client Secret** values.

### **Phase 2: One-Time Authorisation (Getting the Refresh Token)**

You only need to do this once to establish the permission.

1. **Generate Auth URL:** Construct a URL to request permission.

    ```text
    https://accounts.google.com/o/oauth2/v2/auth?
    scope=https://www.googleapis.com/auth/blogger&
    access_type=offline&
    include_granted_scopes=true&
    response_type=code&
    redirect_uri=http://127.0.0.1:8080&
    client_id=[YOUR_CLIENT_ID]
    ```

    *Note: `access_type=offline` is strictly required to get a
    Refresh Token. Use `127.0.0.1` (not `localhost`) as Google
    recommends the loopback IP address for desktop applications.*

2. **Authorise:** Paste this URL into your browser. Log in with
   the Google Account that owns the blog and click "Allow".

3. **Capture Code:** The browser will redirect to your
   `redirect_uri` with a code parameter:
   `http://127.0.0.1:8080/?code=4/0A...` — copy this code.

4. **Exchange for Tokens:** Make a POST request to exchange the
   code.

   * **Endpoint:** <https://oauth2.googleapis.com/token>
   * **Parameters:**
     * `client_id`: [Your ID]
     * `client_secret`: [Your Secret]
     * `code`: [The code you copied]
     * `grant_type`: `authorization_code`
     * `redirect_uri`: `http://127.0.0.1:8080`

5. **Save the Result:** The response will contain an
   `access_token` (1 hr) and a `refresh_token`. **Store the
   Refresh Token securely.**

### **Phase 3: Publishing Script (The Loop)**

Every time your script runs to publish a post:

1. **Check Access Token:** (Optional) If you have a saved access
   token, try to use it.
2. **Refresh if Needed:** If the call fails (401 Unauthorised)
   or you have no token, request a new one:

   * POST to <https://oauth2.googleapis.com/token>
   * `client_id`: [Your ID]
   * `client_secret`: [Your Secret]
   * `refresh_token`: [Your Saved Refresh Token]
   * `grant_type`: `refresh_token`

3. **Publish Post:** Use the valid Access Token in the header
   (`Authorization: Bearer [TOKEN]`) to POST your HTML content
   to:
   <https://www.googleapis.com/blogger/v3/blogs/[BLOG_ID]/posts/>
