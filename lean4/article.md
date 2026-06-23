---
title: "Comparing Lean 4 with Haskell"
author: "[Frank Jung](https://www.linkedin.com/in/frankjung)"
date: 24 June 2026
tags: [lean4, wordpuzzle, programming, functional, dependent types, haskell]
---

![Banner: Learning Lean Functional Programming](images/banner.jpg)

_I've been curious about [dependent types][dependent-types] for some time. After
wrestling with them in [Haskell][haskell-lang], discovering [Lean][lean-lang]
felt like a small revelation. Two weeks in, Lean's proofs-as-values and tighter
types already feel like the missing piece I couldn't quite get in Haskell. My
Haskell background helps; the language still feels familiar enough that the
learning curve is manageable._

_In this post I compare two Word Puzzle solvers I implemented: one in
[Haskell][haskell] and my first program in [Lean 4][lean4]. Below I list the
differences I noticed and why they mattered for design, validation and I/O._

## Overview of the Problem

I built both projects to solve an identical problem: given a pool of 4–9
lowercase letters and a mandatory letter, filter a dictionary file for words
that can be spelt from the pool.

My Haskell version uses pull-based streaming I/O with the `io-streams` library
and applicative validation via `Data.Validation`. For my Lean 4 attempt, I used
dependent types with compile-time proofs and explicit `IO.FS.Handle` streaming.

## Type Declarations and Safety

### Haskell: Record Syntax with Smart Constructor

In my Haskell code, I used a plain product type for the `WordPuzzle` record. The
type itself does not prevent the construction of invalid puzzles:

```haskell
data WordPuzzle = WordPuzzle
  { size       :: Int
  , mandatory  :: Char
  , letters    :: String
  , dictionary :: FilePath
  , repeats    :: Bool
  } deriving (Eq, Show)
```

To enforce validation, I used the
[smart constructor pattern][smart-constructor-pattern]. The module export list
exports the `WordPuzzle` type name but hides its data constructor:

```haskell
module WordPuzzle ( WordPuzzle      -- type only, not constructor
                  , mkWordPuzzle    -- smart constructor
                  , size, mandatory, letters
                  , dictionary, repeats
                  ...
                  ) where
```

Clients must use `mkWordPuzzle`, which performs applicative validation and
accumulates all errors in one pass:

```haskell
mkWordPuzzle :: Bool -> Int -> Char -> String -> FilePath
             -> Validation [ValidationError] WordPuzzle
mkWordPuzzle r s m ls d =
  WordPuzzle <$> validateSize s
             <*> validateMandatory m
             <*> validateLetters ls
             <*> pure d
             <*> pure r
             <* validateMandatoryInLetters m ls
```

The error type is a structured sum type with typed payloads:

```haskell
data ValidationError =
    InvalidSize (Int, Int) Int
    | InvalidLetters String
    | UnexpectedValue String
    | InvalidMandatory Char
    | MandatoryNotInLetters Char String
    deriving (Eq)
```

Each constructor carries the data needed to produce a specific diagnostic.
`InvalidSize` carries both the expected range and the actual value, so the error
message can be rendered precisely.

Once a `WordPuzzle` is constructed, the compiler does not track that validation
has occurred — the invariants are not encoded in the type. Downstream code must
trust that a value was produced through `mkWordPuzzle`.

### Lean 4: Structure with Dependent Type Proof Obligations

Lean 4 embeds proofs of invariants directly into the `Puzzle` structure:

```lean
structure Puzzle where
  private mk ::
  repeats : Bool
  size : Nat
  letters : String
  mandatory : Char
  h_size : 4 ≤ size ∧ size ≤ 9
  h_letters_len : 4 ≤ letters.length ∧ letters.length ≤ 9
  h_letters_lower : letters.toList.all isAsciiLower = true
  h_letters_unique : hasDuplicates letters.toList = false
  h_mandatory_lower : isAsciiLower mandatory = true
  h_mandatory_in : letters.toList.contains mandatory = true
```

Here, `h_size` through `h_mandatory_in` are not just comments; they are
first-class proof terms that must be supplied to construct a `Puzzle`. The
`private mk` annotation restricts the data constructor to the `Wordpuzzle`
namespace — any code outside that namespace must use the `validate` function.

Just like in my Haskell version, `mandatory` is a separate field. I explicitly
validate that `mandatory` appears in `letters` (`h_mandatory_in` in Lean,
`validateMandatoryInLetters` in Haskell) and is itself lowercase. However, Lean
integrates these constraints as proof obligations.

Lean's errors are plain `String` messages collected into a `List String`. This
is simpler than Haskell's structured error sum type but sacrifices the ability
to programmatically inspect error categories without parsing the message text.

#### Proof Discharge

Lean uses compile-time tactics to discharge proofs. For instance, the
`Inhabited` default instance resolves proofs automatically:

```lean
h_size          := by decide  -- decidable arithmetic
h_letters_lower := by rfl     -- definitional equality
```

`by decide` runs a decision procedure for propositions like `4 ≤ 4 ∧ 4 ≤ 9`.
`by rfl` works when the proposition reduces to `true = true` by computation
alone. These are compile-time checks — if the placeholder values were invalid,
the module would not compile.

#### Runtime Validation to Runtime Proofs

To construct a `Puzzle` from user input at runtime, Lean's `validate` function
uses decidable `if`:

```lean
if h : (4 ≤ size ∧ size ≤ 9) ∧
       (4 ≤ letters.length ∧ letters.length ≤ 9) ∧
       (letters.toList.all isAsciiLower = true) ∧
       (hasDuplicates letters.toList = false) ∧
       (isAsciiLower mandatory = true) ∧
       (letters.toList.contains mandatory = true) then
  Except.ok {
    repeats, size, letters, mandatory,
    h_size := h.1, -- first proof
    h_letters_len := h.2.1, -- second proof
    h_letters_lower := h.2.2.1, -- third proof
    h_letters_unique := h.2.2.2.1, -- fourth proof
    h_mandatory_lower := h.2.2.2.2.1, -- fifth proof
    h_mandatory_in := h.2.2.2.2.2 -- sixth proof
  }
else
  Except.error errs
```

The syntax `if h : ... then` is a _dependent_ `if`: when the condition is true,
`h` is bound as a proof of the proposition. The components of `h` (accessed via
`.1`, `.2.1`, etc.) are then used to satisfy the constructor's proof
obligations. This check happens at runtime — the proof term `h` is produced by
the runtime evaluation of the decidable proposition. But once `h` exists, the
_type_ of the resulting `Puzzle` statically guarantees the invariants hold. If
the check fails, the `else` branch returns `Except.error` — no `Puzzle` is
constructed at all.

### Validation Strategy Comparison

When I wrote the Haskell version, I chose `Data.Validation` because it is
deliberately _not_ a monad — it is only an `Applicative`. This means all fields
are validated independently and errors from every field are accumulated.

If both `validateSize` and `validateLetters` fail, both errors appear in the
result. This is the key advantage of `Validation` over `Either`, which
short-circuits on the first error.

Lean uses `Except` (which _is_ monadic and would short-circuit), but I work
around this by collecting errors into a `List String` _before_ wrapping in
`Except`:

```lean
let errs := validateSize size ++
            validateLetters letters ++
            validateMandatory mandatory letters
if errs.isEmpty then ... else Except.error errs
```

Both approaches achieve multi-error accumulation. Haskell encodes it in the type
(`Validation` vs `Either`). Lean encodes it in the control flow (manual list
concatenation then a single `Except` decision).

| Aspect       | Haskell                      | Lean 4                      |
| ------------ | ---------------------------- | --------------------------- |
| Guarantee    | Runtime only                 | Proof-carrying types        |
| Visibility   | Hidden via module exports    | `private mk` in namespace   |
| Error type   | Structured sum type          | Plain `String`              |
| Accumulation | `Validation` applicative     | Manual `List String`        |
| Mandatory Ch | Explicitly validated field   | Explicitly validated field  |

## Pure Functions

I isolated the core filtering logic into pure functions in both projects, but I
noticed their execution models differ quite a bit.

### Haskell: Bitwise Folds and Predicate Composition

My Haskell version optimises for performance using bitwise operations over
packed `ByteString` data. The `nineLetters` function uses a strict left fold
with a bitmask accumulator to check that each character appears in the pool and
is not repeated:

```haskell
nineLetters :: String -> BS.ByteString -> Bool
nineLetters ls = snd . BS.foldl' step (0 :: Int, True)
  where
    step (mask, ok) c
      | not ok            = (mask, False)
      | c `notElem` ls    = (mask, False)
      | mask .&. bit /= 0 = (mask, False)
      | otherwise         = (mask .|. bit, True)
      where
        bit = 1 `shiftL` (ord c - ord 'a')
```

For the repeats-allowed ("Spelling Bee") mode, a simpler check suffices:

```haskell
spellingBee :: String -> BS.ByteString -> Bool
spellingBee ls = BS.all (`elem` ls)
```

The three filter predicates (length, mandatory character, letter pool) are
composed using the `Semigroup` instance of `Predicate` from
`Data.Functor.Contravariant`:

```haskell
solver puzzle = Streams.filter
  (getPredicate (pS <> pM <> pL))
  where
    pS = Predicate $ checkLength (repeats puzzle) (size puzzle)
    pM = Predicate $ hasMandatory (mandatory puzzle)
    pL = Predicate $ checkLettersPool (repeats puzzle)
                                      (letters puzzle)
```

The `<>` on `Predicate` produces a conjunction — a word must satisfy all three
predicates to pass the filter. This is a distinctly Haskell idiom: using
typeclass-driven composition to build complex predicates from simple parts.

### Lean 4: Declarative Option Guard Pipelines

The Lean 4 version uses monadic `guard` within the `Option` monad to build a
declarative filter:

```lean
def solve (puzzle : Puzzle) (word : String)
    : Option String := do
  let puzzleChars := puzzle.letters.toList
  let cleanWord := word.trimAscii.toString
  let wordChars := cleanWord.toList
  guard (
    wordChars.length >= puzzle.size &&
    cleanWord.contains puzzle.mandatory &&
    wordChars.all (fun c => puzzleChars.contains c) &&
    (puzzle.repeats || !hasDuplicates wordChars)
  )
  return cleanWord
```

The return type is `Option String` rather than `Bool` — the function both
filters and returns the cleaned word in one pass. All four conditions are
inlined into a single `guard` expression.

| Aspect       | Haskell                      | Lean 4                      |
| ------------ | ---------------------------- | --------------------------- |
| Return type  | `Bool` (filter predicate)    | `Option String`             |
| Data representation | `ByteString` (packed) | `String` / `List Char`      |
| Composition  | `Predicate` semigroup (`<>`) | `do`/`guard` in `Option`    |
| Bitwise ops  | Manual bitmask               | `List.contains`             |
| Duplicates   | Bit already set in mask      | `hasDuplicates` on list     |

Both are pure. Lean's version is more declarative and closer to the
specification. Haskell's version is more performance-conscious, using bit-level
operations on packed data.

### Totality and Recursion

One major difference I bumped into is how both languages handle recursion:

- **Lean 4** requires functions to be proven **total** (they must terminate on
  all inputs). If a function uses general recursion where termination is not
  provable, it must be explicitly marked with the `partial` keyword.
- **Haskell** does not check for totality. General recursion and potentially
  infinite loops are allowed implicitly.

## IO Handling

### Haskell: Pull-Based Stream Pipelines

Haskell processes file I/O using `io-streams`, a pull-based streaming library.
This is _not_ lazy I/O (which uses `unsafeInterleaveIO`); instead, each stage
explicitly pulls data from its upstream source via `IO` actions:

```haskell
solve :: WordPuzzle -> IO ()
solve wordpuzzle =
  Streams.withFileAsInput (dictionary wordpuzzle) $ \is -> do
    lines_is <- Streams.lines is
    filtered_is <- solver wordpuzzle lines_is
    printed_is <- Streams.mapM_ BS.putStrLn filtered_is
    Streams.skipToEof printed_is
```

The pipeline composes four stages: raw bytes → lines → filtered lines → printed
output. `withFileAsInput` brackets the file handle, ensuring it is closed when
the callback returns. Each `Streams.*` call returns a new `InputStream`,
creating a chain of pull-based transformers. `Streams.skipToEof` drives the
pipeline to completion by consuming all remaining elements.

### Lean 4: Explicit State-Carrying Tail Recursion

Lean 4 does not provide a standard lazy or pull-based stream abstraction for
file handles. Instead, it uses explicit tail recursion:

```lean
partial def streamPuzzle (handle : IO.FS.Handle)
    (puzzle : Puzzle) (foundAny : Bool) : IO UInt32 := do
  let line ← handle.getLine
  if line.isEmpty then
    if !foundAny then
      IO.println "No words found."
    pure (0 : UInt32)
  else
    match solve puzzle line with
    | some matchWord =>
      IO.println matchWord
      streamPuzzle handle puzzle true
    | none =>
      streamPuzzle handle puzzle foundAny
```

Key features of Lean's approach:

- **Partiality**: The function is marked `partial` because the totality checker
  cannot prove that reading from an OS file handle will terminate.
- **State Passing**: The `foundAny` boolean is threaded through recursion to
  track whether any match was found, avoiding mutable global state.
- **Explicit Exit Codes**: Lean's entry point returns `IO UInt32` as part of its
  type signature, making exit codes first-class citizens.
- **Explicit Error Handling**: The `runWordpuzzleCmd` function uses
  `try`/`catch` around file operations, making error handling visible:

```lean
try
  let handle ← IO.FS.Handle.mk dictionary IO.FS.Mode.read
  streamPuzzle handle puzzle false
catch e =>
  IO.println s!"Failed to read dictionary file: {e}"
  return (1 : UInt32)
```

### IO Comparison

| Aspect       | Haskell                      | Lean 4                      |
| ------------ | ---------------------------- | --------------------------- |
| File reading | `Streams.withFileAsInput`    | `IO.FS.Handle.mk`           |
| Stream model | Pull-based `InputStream`     | Manual tail recursion       |
| Termination  | Not checked                  | Explicit (`partial`)        |
| Cleanup      | Bracket (`withFileAsInput`)  | Manual (or `try`/`catch`)   |
| Errors       | Exceptions (unchecked)       | `try`/`catch` in `do`       |
| Exit codes   | Implicit (`IO ()`)           | Explicit (`IO UInt32`)      |

## Immutable Data Structures

Both environments default to immutability, but Lean's compiler enforces
invariant immutability.

- **Haskell**: Records and lists are immutable. Updating record fields creates a
  new value (e.g., `puzzle { size = n }`).
- **Lean 4**: Structures are immutable. Field updates use functional update
  syntax (e.g., `{ s with size := n }`). The `String` type is backed by an
  efficient, immutable UTF-8 `ByteArray`.
- **Proof Invariance**: Because the proofs of validity (e.g., `h_size`) are
  embedded as fields in the `Puzzle` structure, Lean's type system guarantees
  that the invariants hold for any value of type `Puzzle`. You cannot produce a
  `Puzzle` that violates them.

## Mutable Data Structures

Neither language exposes implicit mutable state in the solver logic, but they
differ in how they support explicit mutable references.

### Haskell: Hidden Behind Abstractions

The Haskell wordpuzzle solver does not use `IORef` or `STRef` directly. The
`io-streams` library uses mutable buffers internally, but the user-facing API is
a sequence of `IO` actions that return immutable `InputStream` values. Haskell's
general approach is to hide mutation behind `IO` or `ST` and expose a pure
interface.

The Haskell test suite uses HSpec, which manages test state internally — the
test author writes pure assertions (`shouldBe`) without explicit state tracking.

### Lean 4: IO.Ref for Test State

The Lean test harness uses `IO.Ref` — a mutable reference cell — to track
pass/fail counts explicitly:

```lean
structure State where
  fails : Nat
  total : Nat

def mkState : IO (IO.Ref State) :=
  IO.mkRef { fails := 0, total := 0 }
```

`IO.Ref` is Lean 4's equivalent of Haskell's `IORef`. It requires the `IO` monad
to read or write:

```lean
let s ← st.get
st.set { s with total := total, fails := s.fails + 1 }
```

The functional update syntax `{ s with ... }` creates a new `State` value — the
mutation occurs only in the reference cell, not in the structure itself.

### Mutable State Comparison

| Aspect             | Haskell                | Lean 4               |
| ------------------ | ---------------------- | -------------------- |
| Mutable references | `IORef`, `STRef`       | `IO.Ref`             |
| In production code | Hidden in `io-streams` | Avoided (recursion)  |
| In test code       | Hidden in HSpec        | Explicit `IO.Ref`    |
| State threading    | Pull-based streaming   | Explicit (recursion) |

## Summary of Key Differences

| Aspect       | Haskell                      | Lean 4                      |
| ------------ | ---------------------------- | --------------------------- |
| Type safety  | Runtime smart constructor    | Proof-carrying types        |
| Constructor  | Hidden via module exports    | `private mk` in namespace   |
| Error types  | Structured sum type          | Plain `String` messages     |
| Accumulation | `Validation` applicative     | `List String` concatenation |
| Purity limit | Thin I/O shell, pure core    | Same, explicit partiality   |
| Predicates   | `Predicate` semigroup (`<>`) | Single `guard` expression   |
| Streaming    | Pull-based (`io-streams`)    | Manual tail recursion       |
| Termination  | Not checked                  | `partial` required          |
| Mandatory Ch | Separate validated field     | Separate validated field    |
| Proofs       | None (or LiquidHaskell)      | Built-in structure fields   |
| Mutable      | `IORef`/`STRef` (rare)       | `IO.Ref` (used in tests)    |
| Performance  | Bitwise on `ByteString`      | Higher-level `List Char`    |
| Exit codes   | Implicit (`IO ()`)           | Explicit (`IO UInt32`)      |

While Haskell does not support dependent types natively, it does have libraries
like [LiquidHaskell][liquidhaskell] that can encode some invariants at the type
level. However, these are not first-class features of the language and require
additional tooling and annotations.

## Summary and Reflection

Learning Lean 4 has been invigorating. The proving syntax still trips me up at
times, but the central idea — encoding invariants as part of the type — is
compelling. Porting the Word Puzzle solver made the trade-offs concrete: Lean
moves many checks into the compiler, which changes how validation and error
handling are designed, while Haskell keeps more of that logic at runtime and
remains pragmatic for low-level optimisation.

Lean's proof-carrying types point toward safer designs where correctness is
enforced by types rather than only by tests. Haskell still shines for familiar
tooling and performance idioms, but Lean offers a different, promising angle on
program correctness.

Both implementations can be refined further; these are my initial impressions
while they're still fresh. Let me know if you have any questions or suggestions
for improvement!

## Other Implementations

I use this little puzzle as my "Hello World" when I'm trying out a new language.
I've implemented it in these languages:

- [Clojure][clojure]
- [Flutter][flutter]
- [Go][go]
- [Haskell][haskell]
- [Java][java]
- [Kotlin][kotlin]
- [Lean 4][lean4]
- [Python][python]

[clojure]: https://github.com/frankhjung/clojure-wordpuzzle
[dependent-types]: https://en.wikipedia.org/wiki/Dependent_type
[flutter]: https://github.com/frankhjung/flutter-wordpuzzle
[go]: https://github.com/frankhjung/go-wordpuzzle
[haskell-lang]: https://www.haskell.org/
[haskell]: https://github.com/frankhjung/haskell-wordpuzzle
[java]: https://github.com/frankhjung/java-wordpuzzle
[kotlin]: https://github.com/frankhjung/kotlin-wordpuzzle
[lean-lang]: https://lean-lang.org/
[lean4]: https://github.com/frankhjung/lean4-wordpuzzle
[liquidhaskell]: https://github.com/ucsd-progsys/liquidhaskell
[python]: https://github.com/frankhjung/python-wordpuzzle
[smart-constructor-pattern]: https://wiki.haskell.org/index.php?title=Smart_constructors