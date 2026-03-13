"""Base collector: configured vs unconfigured, no duplicate gathers."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass
class CollectorResult:
    """Result of running a collector (or skipping because unconfigured)."""

    name: str
    configured: bool
    success: bool
    message: str
    data: list[dict[str, Any]] | None = None
    error: str | None = None


class BaseCollector:
    """Base for all NC real estate data collectors."""

    name: str = "base"
    description: str = ""

    def is_configured(self) -> bool:
        """Return True if a reputable source is attached for this collector."""
        return False

    def gather(self, **kwargs: Any) -> CollectorResult:
        """Run the collector. If not configured, return a clear 'nothing configured' result."""
        if not self.is_configured():
            return CollectorResult(
                name=self.name,
                configured=False,
                success=False,
                message="Nothing's configured. Attach a reputable source for this collector (see docs/REPUTABLE_SOURCES.md).",
            )
        return self._gather_impl(**kwargs)

    def _gather_impl(self, **kwargs: Any) -> CollectorResult:
        """Override in subclasses to perform the actual gather when configured."""
        return CollectorResult(
            name=self.name,
            configured=True,
            success=False,
            message="Not implemented.",
        )
