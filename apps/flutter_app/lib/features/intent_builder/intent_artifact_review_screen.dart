import 'dart:convert';

import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter/material.dart';

class IntentArtifactReviewScreen extends StatelessWidget {
  const IntentArtifactReviewScreen({super.key, required this.artifact});

  final IntentCanonicalArtifactModel artifact;

  @override
  Widget build(BuildContext context) {
    final traceJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(artifact.trace);
    return Scaffold(
      appBar: AppBar(title: const Text("ตรวจเวอร์ชันที่เตรียมส่งมอบ")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "สรุปเวอร์ชัน",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("รหัสแผน: ${artifact.intentId}"),
                  const SizedBox(height: 4),
                  Text("รหัสเวอร์ชัน: ${artifact.artifactId}"),
                  if (artifact.promotedFromArtifactId != null &&
                      artifact.promotedFromArtifactId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "คัดลอกจากเวอร์ชัน: ${artifact.promotedFromArtifactId}",
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text("เจ้าของแผน: ${artifact.ownerRef}"),
                  const SizedBox(height: 4),
                  Text("เวอร์ชันสัญญา: ${artifact.contractVersion}"),
                  const SizedBox(height: 4),
                  Text("สถานะ: ${artifact.artifactState.name}"),
                  const SizedBox(height: 4),
                  Text("เวลาที่สร้าง: ${artifact.generatedAt.toLocal()}"),
                  const SizedBox(height: 4),
                  Text("เส้นทางที่เปิดใช้งาน: ${artifact.activeEntryCount}"),
                  const SizedBox(height: 4),
                  Text(
                    "โหมดการส่งมอบ: ${artifact.sealedReleaseCandidate.releaseMode}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ตำแหน่งข้อมูลลับ: ${artifact.sealedReleaseCandidate.deviceSecretResidency}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "เส้นทางในแพ็กส่งมอบ: ${artifact.sealedReleaseCandidate.entries.length}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ผลตรวจคุณภาพ: ติดบล็อก ${artifact.report.errorCount} รายการ / เตือน ${artifact.report.warningCount} รายการ",
                  ),
                  if (artifact.report.errorCount > 0) ...[
                    const SizedBox(height: 4),
                    const Text("ต้องแก้รายการติดบล็อกก่อนปล่อยใช้งาน"),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    artifact.artifactState == IntentArtifactState.ready
                        ? "เวอร์ชันนี้พร้อมใช้งานแล้ว เพราะผ่าน export และ review ครบ"
                        : "เวอร์ชันที่ export ต้องผ่านการ review ก่อน จึงจะถือว่าพร้อมใช้งาน",
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "หากต้องย้อนกลับไปใช้จุดก่อนหน้า คุณสามารถคัดลอกเวอร์ชันเก่ามา export ใหม่ได้",
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "สรุปเงื่อนไขเริ่มทำงาน (อ่านง่าย)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ใช้ส่วนนี้เช็กว่าแต่ละเส้นทางจะเริ่มทำงานเมื่อไหร่ โดยไม่ต้องอ่านโค้ดเทคนิค",
                  ),
                  const SizedBox(height: 10),
                  ...artifact.sealedReleaseCandidate.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFEFF6F5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.assetLabel,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(_triggerSummaryText(entry)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "แพ็กเกจส่งมอบที่ซีลแล้ว",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "รหัสแพ็กเกจ: ${artifact.sealedReleaseCandidate.candidateId}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "เวลาซีลแพ็กเกจ: ${artifact.sealedReleaseCandidate.sealedAt.toLocal()}",
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "แพ็กเกจนี้แสดงเฉพาะสถานะการส่งมอบ ข้อมูลลับยังอยู่ในเครื่อง และมูลค่าจะถูกซ่อนหรือให้ปลายทางยืนยันเท่านั้น",
                  ),
                  const SizedBox(height: 10),
                  ...artifact.sealedReleaseCandidate.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF7F2EA),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.assetLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                "ประเภทเส้นทาง: ${_routeKindLabel(entry.kind)}"),
                            const SizedBox(height: 4),
                            Text("ช่องทางส่งมอบ: ${entry.releaseChannel}"),
                            const SizedBox(height: 4),
                            Text(
                              "ก่อนถึงเงื่อนไข: ${entry.preTriggerVisibility}",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "หลังถึงเงื่อนไข: ${entry.postTriggerVisibility}",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "การเปิดเผยมูลค่า: ${entry.valueDisclosureMode}",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ต้องยืนยันกับพาร์ทเนอร์: ${entry.partnerVerificationRequired ? "ใช่" : "ไม่ใช่"}",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "รายงานปัญหา",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (artifact.report.issues.isEmpty)
                    const Text(
                      "ไม่พบปัญหาในเวอร์ชันที่ export นี้",
                    )
                  else
                    ...artifact.report.issues.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _issueBackground(issue.severity),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _severityLabel(issue.severity),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_issueTitle(issue.code)),
                              const SizedBox(height: 4),
                              Text(
                                _issueAdvice(issue.code),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text("ดูรายละเอียดเทคนิค"),
                                childrenPadding: EdgeInsets.zero,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "[${issue.severity}] ${issue.code}: ${issue.message}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontFamily: "Consolas",
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "บันทึกเทคนิค (Trace)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF7F2EA),
                    ),
                    child: SelectableText(
                      traceJson,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ข้อความนโยบาย (Policy Text)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF7F2EA),
                    ),
                    child: SelectableText(
                      artifact.ptn,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _triggerSummaryText(SealedReleaseEntryModel entry) {
    if (entry.triggerMode == "manual_release") {
      return "เริ่มทำงานเมื่อมีการอนุมัติปลดล็อกฉุกเฉิน และรออีก ${entry.graceDays} วันก่อนส่งมอบสุดท้าย";
    }
    if (entry.triggerMode == "exact_date") {
      final scheduled = entry.scheduledAtUtc;
      if (scheduled == null) {
        return "ตั้งเป็นวันเวลาตายตัว แต่ยังไม่ได้บันทึกวันเวลา กรุณาตรวจทานเส้นทางนี้ก่อนใช้งานจริง";
      }
      return "เริ่มทำงานวันที่ ${_formatDateTime(scheduled.toLocal())} และรออีก ${entry.graceDays} วันก่อนส่งมอบสุดท้าย";
    }
    return "เริ่มทำงานเมื่อไม่พบการใช้งาน ${entry.inactivityDays} วัน และรออีก ${entry.graceDays} วันก่อนส่งมอบสุดท้าย";
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, "0");
    final day = value.day.toString().padLeft(2, "0");
    final hour = value.hour.toString().padLeft(2, "0");
    final minute = value.minute.toString().padLeft(2, "0");
    return "${value.year}-$month-$day $hour:$minute";
  }

  String _routeKindLabel(String value) {
    if (value == "self_recovery") {
      return "กู้คืนด้วยตัวเอง";
    }
    return "ส่งต่อมรดกดิจิทัล";
  }

  String _severityLabel(String value) {
    if (value == "error") {
      return "ต้องแก้ก่อนใช้งาน";
    }
    return "ข้อแนะนำก่อนปล่อยจริง";
  }

  Color _issueBackground(String value) {
    if (value == "error") {
      return const Color(0xFFFFF0F0);
    }
    return const Color(0xFFFFF7E8);
  }

  String _issueTitle(String code) {
    switch (code) {
      case "intent_validation_error":
        return "ข้อมูลสำคัญยังไม่ครบ";
      case "inactive_entry_skipped":
        return "เส้นทางนี้ยังไม่เปิดใช้งาน";
      case "exact_date_in_past":
        return "วันเวลาเริ่มทำงานอยู่ในอดีต";
      case "missing_beneficiary_identity":
        return "ยังไม่ได้ระบุตัวตนผู้รับให้ชัดเจน";
      case "missing_beneficiary_verification_hint":
        return "ยังไม่ได้ตั้งคำใบ้ยืนยันตัวตนผู้รับ";
      case "missing_multi_channel_fallback":
        return "ช่องทางสำรองผู้รับยังไม่พอ";
      case "pretrigger_visibility_too_open":
        return "การมองเห็นก่อนถึงเงื่อนไขเปิดกว้างเกินไป";
      default:
        return "พบจุดที่ควรตรวจทานก่อนปล่อยจริง";
    }
  }

  String _issueAdvice(String code) {
    switch (code) {
      case "intent_validation_error":
        return "กรอกข้อมูลที่ขาดให้ครบ แล้ว export ใหม่อีกครั้ง";
      case "inactive_entry_skipped":
        return "เปิดใช้งานเส้นทางที่ต้องการให้ส่งมอบจริง";
      case "exact_date_in_past":
        return "เปลี่ยนวันเวลาเป็นอนาคต เพื่อกันการส่งมอบทันทีโดยไม่ตั้งใจ";
      case "missing_beneficiary_identity":
        return "ใส่ชื่อผู้รับตามเอกสารจริง เพื่อลดความสับสนตอนรับมรดก";
      case "missing_beneficiary_verification_hint":
        return "เพิ่มคำใบ้ที่มีแค่ผู้รับจริงตอบได้ เพื่อกันมิจฉาชีพ";
      case "missing_multi_channel_fallback":
        return "เพิ่มช่องทางสำรองอย่างน้อย 2 ช่องทาง เช่น Email และ SMS";
      case "pretrigger_visibility_too_open":
        return "ตั้งค่าให้ข้อมูลก่อนถึงเงื่อนไขเป็นแบบซ่อน เพื่อความเป็นส่วนตัว";
      default:
        return "ตรวจทานรายการนี้ก่อน release เพื่อความมั่นใจของผู้ใช้";
    }
  }
}
