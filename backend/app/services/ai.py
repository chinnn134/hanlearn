from __future__ import annotations

import time
from collections import defaultdict, deque
from dataclasses import dataclass
from threading import Lock
from typing import Protocol


@dataclass(frozen=True)
class AiExplainInput:
    uid: str
    vocab_id: str
    hanzi: str
    pinyin: str
    meaning_vi: str
    context_zh: str | None


@dataclass(frozen=True)
class AiExample:
    zh: str
    pinyin: str
    vi: str


@dataclass(frozen=True)
class AiExplainResult:
    explanation_vi: str
    examples: tuple[AiExample, ...]
    radical_note_vi: str | None


class AiProviderError(Exception):
    pass


class AiServiceNotConfigured(AiProviderError):
    pass


class AiServiceUnavailable(AiProviderError):
    pass


class AiServiceTimeout(AiProviderError):
    pass


class AiRateLimited(Exception):
    pass


class AiQuotaExceeded(Exception):
    pass


class AiExplainProvider(Protocol):
    configured: bool

    async def explain(self, item: AiExplainInput) -> AiExplainResult: ...


class UnconfiguredAiProvider:
    configured = False

    async def explain(self, item: AiExplainInput) -> AiExplainResult:
        del item
        raise AiServiceNotConfigured("AI provider is not configured")


class AiRateLimiter(Protocol):
    def consume(self, uid: str) -> None: ...


class InMemoryAiRateLimiter:
    """Single-process contract limiter; replace before multi-instance deployment."""

    def __init__(self, *, per_minute: int, per_day: int) -> None:
        self._per_minute = per_minute
        self._per_day = per_day
        self._events: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def consume(self, uid: str) -> None:
        now = time.time()
        with self._lock:
            events = self._events[uid]
            while events and events[0] <= now - 86_400:
                events.popleft()
            if len(events) >= self._per_day:
                raise AiQuotaExceeded("daily AI quota exceeded")
            recent = sum(timestamp > now - 60 for timestamp in events)
            if recent >= self._per_minute:
                raise AiRateLimited("per-minute AI rate exceeded")
            events.append(now)
