# 01 — Gameplay

## Rules summary

Slide tiles into order.

> Full rules: https://en.wikipedia.org/wiki/15_puzzle

## Controls

Tap an adjacent-to-blank tile to slide it. Long-press for hint (next-solvable move).

## Screen flow

1. Game (board + moves counter + timer)
2. Win dialog (moves, time, best, 'New game')

## Difficulty

Single difficulty; 'Shuffle' uses 200 random legal moves to guarantee solvability.

## Scoring

Track moves and time. Persist 'best_moves' and 'best_time'.

## State machine

The game moves through these states: **playing, won**.

```
      ┌──────────────┐
      │   playing    │
      └──┬───┬───┬───┘
         │   │   │
         │   │   └──► won
```
