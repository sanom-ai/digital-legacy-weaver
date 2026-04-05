from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True)
class DispatchDecision:
    should_release: bool
    reason: str


@dataclass(frozen=True)
class DispatchInput:
    owner_id: str
    mode: str
    inactive_days: int
    threshold_days: int
    legal_accepted: bool
    emergency_pause_until: datetime | None
    has_recent_multisignal: bool
    guardian_approved: bool


class DispatchPolicyAdapter(Protocol):
    def evaluate(self, request: DispatchInput) -> DispatchDecision:
        ...


class DefaultDispatchPolicyAdapter:
    def evaluate(self, request: DispatchInput) -> DispatchDecision:
        if request.emergency_pause_until is not None:
            return DispatchDecision(False, "emergency pause active")
        if not request.legal_accepted:
            return DispatchDecision(False, "legal consent missing")
        if request.has_recent_multisignal:
            return DispatchDecision(False, "recent multi-signal proof-of-life detected")
        if request.mode == "legacy" and not request.guardian_approved:
            return DispatchDecision(False, "guardian approval missing for legacy release")
        if request.inactive_days < request.threshold_days:
            return DispatchDecision(False, "inactive period below threshold")
        return DispatchDecision(True, "policy-approved")
