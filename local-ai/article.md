---
title: "Running Local AI Models"
author: "[Frank Jung](https://www.linkedin.com/in/frankjung/)"
date: 11 February 2026
tags: [ai, local ai, machine learning]
---

![Banner: description](images/banner.jpg)

As AI models become more powerful, they are also becoming much more accessible.
I have been interested in what happens when you trade a little model accuracy
for the ability to run everything on your own machine, without relying on paid
cloud infrastructure. For developers, researchers, and hobbyists, that shift is
useful for more than just cost. It also changes how private, flexible, and
portable these tools can be.

This week I spent some time trying two popular ways of running local AI models:
[Ollama](https://ollama.com/) and [LM Studio](https://lmstudio.ai/). Both are
open source and free to use, and both make it much easier to get started than I
expected. What I wanted to understand was not just whether they worked, but how
they felt to use in practice and where each one made more sense.

What I like about running models locally is that the benefits are immediate.
There is the obvious cost saving, especially if you are experimenting often or
working through lots of prompts, but privacy matters just as much. When the
model runs on my machine, my data stays on my machine. I also get more control
over the environment, the model configuration, and the way everything is wired
together. On top of that, local models can still be useful when I am offline,
which is something cloud tools simply cannot offer.

Of the two options, Ollama felt more direct to me. It was easy to install, easy
to set up, and its command-line workflow suited the way I prefer to work. I was
able to download models quickly, and I liked that I could configure behaviour
through files or environment variables rather than having to click through a
user interface. It also supports a wide range of models, including
[GGUF models](https://huggingface.co/docs/hub/en/gguf) from
[Hugging Face](https://huggingface.co/), so it did not feel restrictive.

LM Studio left a different impression. It is also easy to install and set up,
but it is clearly designed for people who prefer a graphical interface. Model
management is simpler to see at a glance, downloading models is straightforward,
and the interface gives better feedback about which models are likely to work on
your hardware. I also liked that it has built-in support for experimenting with
RAG workflows, which makes it feel more complete if you want to explore beyond
simple chat use cases.

To actually use the models in my daily workflow, I connected them to the
[VS Code Continue Extension](https://marketplace.visualstudio.com/items?itemName=Continue.continue).
That let me interact with the models directly from VS Code, which is where I
already spend most of my time. In practice, this was one of the more useful
parts of the experiment, because it made the local models feel less like a demo
and more like something I could genuinely build into normal development work.

The limitations are real, though, and they show up quickly if your hardware is
modest. In my experience, you need at least 16 GB of RAM to run even the smaller
models with any reasonable performance, and a GPU makes a substantial difference
if you want the models to feel responsive. Larger models are even more
demanding, so running locally is not automatically the right choice just because
it is possible. If you want your model to interact with external tools or with
your local machine in a richer way, you also need to set up local tools such as
MCP, which adds another layer of configuration.

After trying both, I came away thinking that local AI is now genuinely practical
for some workflows, but it still depends heavily on the machine you have
available. On my hardware, Ollama was the easier fit, especially when I paired
it with Continue in VS Code. LM Studio, on the other hand, gave me a better user
interface for chats and model management, and I appreciated how clearly it
surfaced hardware compatibility. Both were straightforward to set up with
Ansible, although Ollama involved a little more user-management work. If I had
to summarise the difference in one sentence, I would say that Ollama felt more
natural for my developer workflow, while LM Studio felt more polished as a
desktop application.
