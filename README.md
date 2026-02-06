![Linux](https://img.shields.io/badge/OS-Linux-black?logo=linux)
![Python](https://img.shields.io/badge/Python-3-blue?logo=python)
![Status](https://img.shields.io/badge/Status-Active-success)
![Safety](https://img.shields.io/badge/AI-Safety--First-critical)
![License](https://img.shields.io/badge/License-MIT-yellow)


# Linux-AI

Linux-AI is a safety-first, local AI assistant for Linux systems.

It analyzes command intent, detects risk, and learns from user behavior —
without executing commands, modifying the shell, or requiring cloud access.

## Features
- Intent analysis (what the user is trying to do)
- Risk classification
- Human-in-the-loop learning
- Negative learning (refuses unsafe patterns)
- Time-based decay & forgetting
- Fully local & explainable

## Installation

```bash
chmod +x install_linux_ai.sh
./install_linux_ai.sh

## Usage

## Usage

Linux-AI is an analysis tool.  
It does **not** execute commands or modify your system.

You use Linux-AI to **analyze a command before running it**, to understand:
- what the command is trying to do
- how risky it is
- whether you have made a similar mistake before
- what a safer or corrected command looks like

### Basic usage

Type the command you want to analyze after `ai`:

```bash
ai sudosudo vim test.txt

Linux-AI will analyze the command and print:

the detected intent

a risk level

an explanation

a suggested correction (if any)

Learning example

Linux-AI learns from your corrections over time.

ai sudosudo vim test.txt
ai sudo vim test.txt
ai sudosudo vim config.yml


On the third command, Linux-AI may suggest:

sudo vim config.yml


with a high confidence score, based on your past behavior.

## Important note

Linux-AI never runs commands for you.

If you want to actually execute a command, you still run it normally in the shell:

sudo vim config.yml


Linux-AI is meant to be a thinking step before execution, not a replacement for the shell.
