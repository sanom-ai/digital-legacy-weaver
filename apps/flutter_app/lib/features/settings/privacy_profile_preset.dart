class PrivacyProfilePreset {
  const PrivacyProfilePreset({
    required this.id,
    required this.title,
    required this.summary,
    required this.detail,
    required this.privateFirstMode,
    required this.tracePrivacyProfile,
    this.recommended = false,
  });

  final String id;
  final String title;
  final String summary;
  final String detail;
  final bool privateFirstMode;
  final String tracePrivacyProfile;
  final bool recommended;
}

const privacyProfilePresets = <PrivacyProfilePreset>[
  PrivacyProfilePreset(
    id: 'confidential',
    title: 'Confidential',
    summary: 'เก็บ trace ให้น้อยที่สุด เหลือเพียง outcome ระดับสูง',
    detail: 'เหมาะกับผู้ใช้ที่ต้องการลดร่องรอย runtime metadata ให้มากที่สุดและยอมแลกกับการตรวจสอบย้อนหลังที่บางลง',
    privateFirstMode: true,
    tracePrivacyProfile: 'confidential',
  ),
  PrivacyProfilePreset(
    id: 'minimal',
    title: 'Minimal',
    summary: 'สมดุลที่สุด เก็บเฉพาะ control-state ที่ sanitize แล้ว',
    detail: 'เหมาะกับ closed beta และการใช้งานทั่วไป เพราะยังตรวจสอบ flow ได้โดยไม่เก็บรายละเอียดเกินจำเป็น',
    privateFirstMode: true,
    tracePrivacyProfile: 'minimal',
    recommended: true,
  ),
  PrivacyProfilePreset(
    id: 'audit-heavy',
    title: 'Audit-heavy',
    summary: 'เพิ่ม evidence/owner reference เพื่อการวิเคราะห์ย้อนหลัง',
    detail: 'เหมาะกับทีมที่ต้องการสืบเหตุการณ์และทำ incident review ลึกขึ้น โดยยังไม่เก็บ secret จริง',
    privateFirstMode: true,
    tracePrivacyProfile: 'audit-heavy',
  ),
];

PrivacyProfilePreset presetById(String id) {
  return privacyProfilePresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => privacyProfilePresets[1],
  );
}
