import 'package:digital_legacy_weaver/features/intent_builder/intent_runtime_readiness_model.dart';
import 'package:flutter/material.dart';

class IntentRuntimeReadinessScreen extends StatelessWidget {
  const IntentRuntimeReadinessScreen({super.key, required this.readiness});

  final IntentRuntimeReadinessModel readiness;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ความพร้อมก่อนปล่อยใช้งานจริง")),
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
                    "สรุปสำหรับผู้ใช้จริง",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "หน้านี้คือด่านสุดท้ายก่อนเปิดใช้การส่งมอบจริง เพื่อให้มั่นใจว่าแผนปลอดภัยและใช้งานได้จริง ไม่ใช่แค่ร่างทดลอง",
                  ),
                  const SizedBox(height: 12),
                  Text(
                    readiness.readinessLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(readiness.summary),
                  const SizedBox(height: 12),
                  Text(readiness.nextStep),
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
                    "รายการตรวจพร้อมใช้งาน",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _CriterionRow(
                    label: "มีเวอร์ชันที่ Export แล้ว",
                    satisfied: readiness.hasArtifact,
                  ),
                  _CriterionRow(
                    label: "เวอร์ชันที่ Export ถูกตั้งเป็นพร้อมใช้งาน",
                    satisfied:
                        readiness.currentArtifact?.artifactState.name ==
                        'ready',
                  ),
                  _CriterionRow(
                    label: "มีเส้นทางที่เปิดใช้งานอย่างน้อย 1 รายการ",
                    satisfied:
                        (readiness.currentArtifact?.activeEntryCount ?? 0) > 0,
                  ),
                  _CriterionRow(
                    label: "ไม่มีปัญหาระดับบล็อกการปล่อยใช้งาน",
                    satisfied: !readiness.hasBlockingErrors,
                  ),
                  _CriterionRow(
                    label: "ร่างปัจจุบันตรงกับเวอร์ชันล่าสุด",
                    satisfied: readiness.draftInSync,
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
                    "ตัวชี้วัดความพร้อม",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("จำนวนเวอร์ชันย้อนหลัง: ${readiness.historyCount}"),
                  Text("เวอร์ชันที่พร้อมใช้งาน: ${readiness.readyArtifactCount}"),
                  Text(
                    "เวอร์ชันที่รีวิวแล้ว: ${readiness.reviewedArtifactCount}",
                  ),
                  Text(
                    "เวอร์ชันที่โปรโมตแล้ว: ${readiness.promotedArtifactCount}",
                  ),
                  Text("คำเตือนที่ต้องตรวจ: ${readiness.warningCount}"),
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
                    "จุดที่ยังต้องแก้ก่อนปล่อยจริง",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (readiness.blockers.isEmpty)
                    const Text(
                      "ไม่มีตัวบล็อก เวอร์ชันนี้พร้อมสำหรับการใช้งานจริง",
                    )
                  else
                    ...readiness.blockers.map(
                      (blocker) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text("- $blocker"),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ภาพรวม 3 ชั้นของระบบ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "1. ชั้นผู้ใช้: ตั้งค่า ตรวจทาน และเช็กความพร้อมแบบเข้าใจง่าย",
                  ),
                  SizedBox(height: 4),
                  Text(
                    "2. ชั้นนโยบาย: คุมกฎความปลอดภัยและการตรวจเงื่อนไขให้คงเส้นคงวา",
                  ),
                  SizedBox(height: 4),
                  Text(
                    "3. ชั้นส่งมอบ: ปล่อยข้อมูลเท่าที่นโยบายอนุญาตในแต่ละเส้นทางผู้รับ",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
