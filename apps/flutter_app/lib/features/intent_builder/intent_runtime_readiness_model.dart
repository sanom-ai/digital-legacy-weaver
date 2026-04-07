import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_document_signature.dart';

// Legacy copy anchors kept for compatibility tests:
// "Ready for release"
// "Needs attention"

class IntentRuntimeReadinessModel {
  const IntentRuntimeReadinessModel({
    required this.currentArtifact,
    required this.currentDraft,
    required this.historyCount,
    required this.readyArtifactCount,
    required this.reviewedArtifactCount,
    required this.promotedArtifactCount,
    required this.draftInSync,
    required this.blockers,
  });

  final IntentCanonicalArtifactModel? currentArtifact;
  final IntentDocumentModel? currentDraft;
  final int historyCount;
  final int readyArtifactCount;
  final int reviewedArtifactCount;
  final int promotedArtifactCount;
  final bool draftInSync;
  final List<String> blockers;

  bool get hasArtifact => currentArtifact != null;

  bool get hasBlockingErrors => (currentArtifact?.report.errorCount ?? 0) > 0;

  int get warningCount => currentArtifact?.report.warningCount ?? 0;

  int get sealedReleaseEntryCount =>
      currentArtifact?.sealedReleaseCandidate.entries.length ?? 0;

  bool get deviceOnlySecretResidency =>
      currentArtifact?.sealedReleaseCandidate.deviceSecretResidency ==
      "device_local_only";

  bool get guardianQuorumEnabled =>
      currentDraft?.globalSafeguards.guardianQuorumEnabled ?? false;

  bool get emergencyAccessEnabled =>
      currentDraft?.globalSafeguards.emergencyAccessEnabled ?? false;

  bool get deviceRebindInProgress =>
      currentDraft?.globalSafeguards.deviceRebindInProgress ?? false;

  String? get currentScenarioId =>
      currentDraft?.metadata["demo_scenario"] as String?;

  String? get currentScenarioTitle =>
      currentDraft?.metadata["demo_title"] as String?;

  String? get currentScenarioSummary =>
      currentDraft?.metadata["demo_summary"] as String?;

  String? get currentScenarioNextStep =>
      currentDraft?.metadata["demo_next_step"] as String?;

  bool get readyForRuntime =>
      currentArtifact != null &&
      currentArtifact!.artifactState == IntentArtifactState.ready &&
      currentArtifact!.activeEntryCount > 0 &&
      !hasBlockingErrors &&
      draftInSync;

  String get readinessLabel {
    if (readyForRuntime) {
      return "พร้อมใช้งาน";
    }
    if (!hasArtifact) {
      return "มีแค่แบบร่าง";
    }
    return "ต้องตรวจเพิ่ม";
  }

  String get summary {
    if (!hasArtifact) {
      return "ตอนนี้ยังมีแค่แบบร่างในเครื่อง ยังไม่มีฉบับพร้อมส่งสำหรับใช้งานจริง";
    }
    final artifact = currentArtifact!;
    if (readyForRuntime) {
      return "ฉบับล่าสุด ${artifact.artifactId} พร้อมใช้งาน ตรงกับแบบร่างปัจจุบัน และมีรายการส่งมอบที่ผนึกไว้ ${artifact.sealedReleaseCandidate.entries.length} รายการ";
    }
    return "ฉบับล่าสุด ${artifact.artifactId} อยู่ในสถานะ ${_artifactStateLabel(artifact.artifactState)} มีเส้นทางที่เปิดใช้งาน ${artifact.activeEntryCount} รายการ และมีรายการส่งมอบที่ผนึกไว้ ${artifact.sealedReleaseCandidate.entries.length} รายการ ควรตรวจจุดที่ยังค้างก่อนใช้งานจริง";
  }

  String get nextStep {
    if (!hasArtifact) {
      return "ขั้นถัดไป: สร้างฉบับพร้อมส่งชุดแรกจากแบบร่างปัจจุบัน";
    }
    if (deviceRebindInProgress) {
      return "ขั้นถัดไป: ปิดงานย้ายอุปกรณ์ก่อน แล้วค่อยยืนยันการเช็กอินก่อนปล่อยใช้งาน";
    }
    if (guardianQuorumEnabled &&
        (currentDraft?.globalSafeguards.guardianQuorumRequired ?? 0) >
            (currentDraft?.globalSafeguards.guardianQuorumPoolSize ?? 0)) {
      return "ขั้นถัดไป: แก้การตั้งค่าพยาน เพราะจำนวนที่ต้องอนุมัติมากกว่าจำนวนพยานที่ตั้งไว้";
    }
    if (hasBlockingErrors) {
      return "ขั้นถัดไป: แก้ปัญหาระดับบล็อกก่อนขยับฉบับนี้ต่อ";
    }
    if ((currentArtifact?.activeEntryCount ?? 0) == 0) {
      return "ขั้นถัดไป: เปิดใช้งานอย่างน้อย 1 เส้นทางก่อนใช้ฉบับนี้จริง";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.exported) {
      return "ขั้นถัดไป: ตรวจทานฉบับพร้อมส่งก่อนตั้งเป็นพร้อมใช้งาน";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed &&
        !draftInSync) {
      return "ขั้นถัดไป: สร้างฉบับพร้อมส่งใหม่ เพราะแบบร่างเปลี่ยนหลังตรวจทาน";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed) {
      return "ขั้นถัดไป: ตั้งฉบับที่ตรวจแล้วเป็นพร้อมใช้งาน ขณะที่แบบร่างยังตรงกัน";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.ready &&
        !draftInSync) {
      return "ขั้นถัดไป: สร้างฉบับพร้อมส่งใหม่จากแบบร่างล่าสุด เพื่ออัปเดตฉบับพร้อมใช้งาน";
    }
    return "ขั้นถัดไป: ตรวจสถานะล่าสุดในหน้าจัดแผน";
  }

  String get primaryActionLabel {
    if (!hasArtifact) {
      return "สร้างฉบับแรก";
    }
    if (deviceRebindInProgress) {
      return "ปิดงานย้ายอุปกรณ์";
    }
    if (guardianQuorumEnabled &&
        (currentDraft?.globalSafeguards.guardianQuorumRequired ?? 0) >
            (currentDraft?.globalSafeguards.guardianQuorumPoolSize ?? 0)) {
      return "แก้การตั้งค่าพยาน";
    }
    if (hasBlockingErrors) {
      return "แก้จุดที่บล็อก";
    }
    if ((currentArtifact?.activeEntryCount ?? 0) == 0) {
      return "เปิดใช้งานรายการ";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.exported) {
      return "ตรวจทานฉบับพร้อมส่ง";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed &&
        !draftInSync) {
      return "สร้างฉบับใหม่";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed) {
      return "ตั้งเป็นพร้อมใช้งาน";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.ready &&
        !draftInSync) {
      return "อัปเดตจากแบบร่างล่าสุด";
    }
    return "ดูพื้นที่ทำงาน";
  }

  String get primaryActionKey {
    if (!hasArtifact) {
      return "export_first_artifact";
    }
    if (deviceRebindInProgress) {
      return "complete_device_rebind";
    }
    if (guardianQuorumEnabled &&
        (currentDraft?.globalSafeguards.guardianQuorumRequired ?? 0) >
            (currentDraft?.globalSafeguards.guardianQuorumPoolSize ?? 0)) {
      return "fix_guardian_quorum";
    }
    if (hasBlockingErrors) {
      return "fix_blocking_issues";
    }
    if ((currentArtifact?.activeEntryCount ?? 0) == 0) {
      return "activate_entries";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.exported) {
      return "review_exported_artifact";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed &&
        !draftInSync) {
      return "refresh_exported_artifact";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.reviewed) {
      return "mark_artifact_ready";
    }
    if (currentArtifact!.artifactState == IntentArtifactState.ready &&
        !draftInSync) {
      return "reexport_latest_draft";
    }
    return "inspect_current_workspace";
  }

  List<String> get actionPlan {
    final steps = <String>[];
    if (!hasArtifact) {
      steps.add("เปิดหน้าจัดแผน แล้วสร้างฉบับพร้อมส่งชุดแรก");
    } else if (deviceRebindInProgress) {
      steps.add(
        "ตอนนี้กำลังย้ายการใช้งานข้ามอุปกรณ์ ให้ปิดงานย้ายให้เสร็จก่อน แล้วค่อยยืนยันการเช็กอินก่อนปล่อยใช้งานจริง",
      );
    } else if (guardianQuorumEnabled &&
        (currentDraft?.globalSafeguards.guardianQuorumRequired ?? 0) >
            (currentDraft?.globalSafeguards.guardianQuorumPoolSize ?? 0)) {
      steps.add(
        "ลดจำนวนพยานที่ต้องอนุมัติ หรือเพิ่มจำนวนพยานในระบบ เพื่อให้เงื่อนไขใช้งานได้จริง",
      );
    } else if (hasBlockingErrors) {
      steps.add(
        "แก้ปัญหาระดับบล็อกก่อนขยับฉบับปัจจุบันต่อ",
      );
    } else if ((currentArtifact?.activeEntryCount ?? 0) == 0) {
      steps.add(
        "เปิดใช้งานอย่างน้อย 1 รายการ เพื่อให้การส่งมอบมีเส้นทางจริง",
      );
    } else if (currentArtifact!.artifactState == IntentArtifactState.exported) {
      steps.add(
        "ตรวจทานฉบับพร้อมส่ง และเช็กผลรายงานก่อนปล่อยใช้งานจริง",
      );
    } else if (currentArtifact!.artifactState == IntentArtifactState.reviewed &&
        !draftInSync) {
      steps.add(
        "สร้างฉบับใหม่จากแบบร่างล่าสุด เพราะฉบับที่เคยตรวจแล้วไม่ตรงกับข้อมูลปัจจุบัน",
      );
    } else if (currentArtifact!.artifactState == IntentArtifactState.reviewed) {
      steps.add(
        "ตั้งฉบับที่ตรวจแล้วเป็นพร้อมใช้งาน ขณะที่แบบร่างยังตรงกัน",
      );
    } else if (currentArtifact!.artifactState == IntentArtifactState.ready &&
        !draftInSync) {
      steps.add(
        "สร้างฉบับพร้อมส่งใหม่จากแบบร่างล่าสุด เพื่อคืนความมั่นใจก่อนใช้งานจริง",
      );
    } else {
      steps.add(
        "รักษาฉบับพร้อมใช้งานให้ตรงกับแบบร่างทุกครั้งที่มีการแก้ไขสำคัญ",
      );
    }

    if (currentScenarioNextStep != null) {
      steps.add(currentScenarioNextStep!);
    }

    if (!draftInSync && hasArtifact) {
      steps.add(
        "เทียบฉบับล่าสุดกับแบบร่างปัจจุบันก่อนโปรโมตหรือสร้างฉบับใหม่",
      );
    }

    if (deviceOnlySecretResidency) {
      steps.add(
        "ข้อมูลลับยังอยู่เฉพาะในเครื่องนี้ ควรเช็กเส้นทางส่งมอบให้แน่ใจว่ายังทำงานได้ถ้าเจ้าของเปลี่ยนอุปกรณ์",
      );
    }

    if (guardianQuorumEnabled) {
      final required =
          currentDraft?.globalSafeguards.guardianQuorumRequired ?? 0;
      final poolSize =
          currentDraft?.globalSafeguards.guardianQuorumPoolSize ?? 0;
      steps.add(
        "ระบบพยานเปิดใช้งานอยู่ โดยต้องให้พยานอนุมัติ $required จากทั้งหมด $poolSize คน",
      );
    }

    if (emergencyAccessEnabled) {
      final safeguards = currentDraft?.globalSafeguards;
      final graceHours = safeguards?.emergencyAccessGraceHours ?? 0;
      final beneficiaryRequest =
          safeguards?.emergencyAccessRequiresBeneficiaryRequest ?? false;
      final guardianRequirement =
          safeguards?.emergencyAccessRequiresGuardianQuorum ?? false;
      steps.add(
        "โหมดฉุกเฉินเปิดใช้งานอยู่ มีช่วงรอ ${graceHours.toString()} ชั่วโมง${beneficiaryRequest ? ", ต้องมีคำขอจากผู้รับ" : ""}${guardianRequirement ? ", และต้องมีพยานร่วมอนุมัติ" : ""}",
      );
    }

    if (currentDraft?.globalSafeguards.recoveryKeyEnabled == true) {
      steps.add(
        "เปิดคีย์กู้คืนสำรองไว้แล้ว สำหรับกรณีเช็กอินสะดุดระหว่างย้ายอุปกรณ์",
      );
    }

    final safeguards = currentDraft?.globalSafeguards;
    if (safeguards != null) {
      steps.add(
        "นโยบายเก็บข้อมูล: ลิงก์เข้าถึง ${safeguards.deliveryAccessTtlHours} ชม. ข้อมูลส่งมอบ ${safeguards.payloadRetentionDays} วัน และบันทึกตรวจสอบ ${safeguards.auditLogRetentionDays} วัน",
      );
    }

    return steps;
  }

  static IntentRuntimeReadinessModel fromArtifacts({
    required IntentCanonicalArtifactModel? currentArtifact,
    required IntentDocumentModel? currentDraft,
    required List<IntentCanonicalArtifactModel> artifactHistory,
  }) {
    final draftSignature = currentDraft == null
        ? null
        : buildIntentDocumentSignature(currentDraft);
    final draftInSync =
        currentArtifact == null ||
        draftSignature == null ||
        currentArtifact.sourceDraftSignature == draftSignature;

    final blockers = <String>[];
    if (currentArtifact == null) {
      blockers.add("ยังไม่มีฉบับพร้อมส่ง");
    } else {
      if (currentArtifact.report.errorCount > 0) {
        blockers.add("ยังมีปัญหาระดับบล็อก");
      }
      if (currentArtifact.activeEntryCount == 0) {
        blockers.add("ยังไม่มีเส้นทางที่เปิดใช้งานในฉบับนี้");
      }
      if (currentArtifact.artifactState == IntentArtifactState.exported) {
        blockers.add("ฉบับพร้อมส่งยังไม่ได้ตรวจทาน");
      }
      if (currentArtifact.artifactState == IntentArtifactState.reviewed &&
          !draftInSync) {
        blockers.add("แบบร่างเปลี่ยนหลังตรวจทาน");
      }
      if (currentArtifact.artifactState == IntentArtifactState.ready &&
          !draftInSync) {
        blockers.add("ฉบับพร้อมใช้งานไม่ตรงกับแบบร่างล่าสุด");
      }
    }

    final safeguards = currentDraft?.globalSafeguards;
    if (safeguards != null) {
      if (safeguards.deviceRebindInProgress) {
        blockers.add("กำลังอยู่ในช่วงย้ายการใช้งานข้ามอุปกรณ์");
      }
      if (safeguards.guardianQuorumEnabled &&
          safeguards.guardianQuorumRequired >
              safeguards.guardianQuorumPoolSize) {
        blockers.add("จำนวนพยานที่ต้องอนุมัติมากกว่าจำนวนพยานที่ตั้งไว้");
      }
      if (safeguards.guardianQuorumEnabled &&
          safeguards.guardianQuorumRequired < 2) {
        blockers.add(
          "จำนวนพยานที่ต้องอนุมัติยังน้อยเกินไปสำหรับแผนที่อ่อนไหว",
        );
      }
      if (safeguards.emergencyAccessEnabled &&
          safeguards.emergencyAccessRequiresGuardianQuorum &&
          !safeguards.guardianQuorumEnabled) {
        blockers.add(
          "โหมดฉุกเฉินกำหนดให้มีพยาน แต่ระบบพยานยังปิดอยู่",
        );
      }
      if (safeguards.emergencyAccessEnabled &&
          !safeguards.emergencyAccessRequiresBeneficiaryRequest) {
        blockers.add(
          "โหมดฉุกเฉินควรกำหนดให้ผู้รับยื่นคำขอก่อน",
        );
      }
    }

    return IntentRuntimeReadinessModel(
      currentArtifact: currentArtifact,
      currentDraft: currentDraft,
      historyCount: artifactHistory.length,
      readyArtifactCount: artifactHistory
          .where(
            (artifact) => artifact.artifactState == IntentArtifactState.ready,
          )
          .length,
      reviewedArtifactCount: artifactHistory
          .where(
            (artifact) =>
                artifact.artifactState == IntentArtifactState.reviewed,
          )
          .length,
      promotedArtifactCount: artifactHistory
          .where(
            (artifact) =>
                artifact.promotedFromArtifactId != null &&
                artifact.promotedFromArtifactId!.isNotEmpty,
          )
          .length,
      draftInSync: draftInSync,
      blockers: blockers,
    );
  }

  String _artifactStateLabel(IntentArtifactState state) {
    switch (state) {
      case IntentArtifactState.draft:
        return "แบบร่าง";
      case IntentArtifactState.exported:
        return "ฉบับพร้อมส่ง";
      case IntentArtifactState.reviewed:
        return "ตรวจทานแล้ว";
      case IntentArtifactState.ready:
        return "พร้อมใช้งาน";
    }
  }
}
