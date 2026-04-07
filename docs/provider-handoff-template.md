# Provider Handoff Template

## Purpose

Standard outbound message template for beneficiary and destination provider coordination.

## Boundary statement (must include)

Digital Legacy Weaver is a technical coordination layer only.  
It does not adjudicate legal entitlement or replace provider legal/compliance decisions.

## Beneficiary-facing template

Subject:

- `แจ้งเตือนแผนรับมรดกดิจิทัลที่ตั้งไว้ล่วงหน้า | Digital Legacy Weaver`

Body:

1. คุณได้รับข้อความนี้เพราะเจ้าของแต่งตั้งคุณไว้ล่วงหน้า (You are pre-assigned by the owner).
2. ข้อความนี้จะไม่ขอให้โอนเงิน ขอรหัสผ่าน หรือเก็บค่าธรรมเนียม (No transfer/password/fee request).
3. คุณไม่จำเป็นต้องรีบดำเนินการทันที หากไม่มั่นใจให้ปรึกษาพยานหรือญาติอีกคนก่อน.
4. เส้นทางที่ปลอดภัยกว่า: เปิดแอปด้วยตัวเอง แล้วกรอก handoff packet (`access_id` + `access_key`) แทนการคลิกลิงก์ที่ไม่แน่ใจ.
5. ติดต่อผู้ให้บริการปลายทางโดยตรงเพื่อยืนยันสิทธิ์ทางกฎหมาย.
6. ส่งเอกสารตามกระบวนการของผู้ให้บริการปลายทาง (ไม่ใช่ส่งให้แพลตฟอร์มนี้).
7. ทำขั้นตอน KYC/AML/2FA ตามที่ผู้ให้บริการกำหนด.
8. แพลตฟอร์มนี้ทำหน้าที่ประสานงานทางเทคนิคเท่านั้น ไม่ได้ตัดสินสิทธิ์ทางกฎหมาย.

## Provider-facing summary fields

When sending handoff context to partners, include:

1. `case_id`
2. `owner_ref`
3. `beneficiary_ref` (if available)
4. `mode` (`legacy` | `self_recovery`)
5. `trigger_timestamp`
6. `handoff_disclaimer`
7. `audit_reference`

Do not include plaintext secrets.
