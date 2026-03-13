"""NC Real Estate data collectors.

Each collector corresponds to a domain (listings, public records, permits, etc.).
Unconfigured collectors return a clear 'nothing configured' result so we don't
scrape or call external sources until a reputable source is attached.
"""

from .base import BaseCollector, CollectorResult
from .public_records import PublicRecordsCollector
from .permits import PermitsCollector
from .deeds import DeedsCollector
from .foreclosures import ForeclosuresCollector
from .tax_records import TaxRecordsCollector
from .zoning import ZoningCollector
from .listings import ListingsCollector
from .laws_regs import LawsRegsCollector

__all__ = [
    "BaseCollector",
    "CollectorResult",
    "PublicRecordsCollector",
    "PermitsCollector",
    "DeedsCollector",
    "ForeclosuresCollector",
    "TaxRecordsCollector",
    "ZoningCollector",
    "ListingsCollector",
    "LawsRegsCollector",
]

COLLECTORS = [
    PublicRecordsCollector(),
    PermitsCollector(),
    DeedsCollector(),
    ForeclosuresCollector(),
    TaxRecordsCollector(),
    ZoningCollector(),
    ListingsCollector(),
    LawsRegsCollector(),
]
