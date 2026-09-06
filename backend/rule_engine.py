import json
import os
import re
from typing import Dict, Any, List, Tuple

class LegalComplianceEngine:
    """
    Legal Metrology Act, 2009 & Packaged Commodities Rules, 2011 Compliance Engine
    Verifies the 9 statutory fields, checks exemptions, and calculates statutory penalties.
    """

    def __init__(self, knowledge_dir: str = "Knowledgebase"):
        self.knowledge_dir = knowledge_dir
        self.rulebook = self._load_json("rulebook.json")
        self.penalty_matrix = self._load_json("penalty_matrix.json")
        self.exemptions = self._load_json("exemptions.json")

    def _load_json(self, filename: str):
        path = os.path.join(self.knowledge_dir, filename)
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        return {}

    def check_exemption(self, net_quantity_str: str, product_type: str = "general") -> Tuple[bool, Optional[str]]:
        """
        Check statutory exemptions under Rule 26 of PCR 2011:
        1. Small Packages (<= 10g or 10ml) - LM-EX-001
        2. Bulk / Heavy Packages (> 25kg or 25L) - LM-PC-003
        """
        match = re.search(r"([\d\.]+)\s*(g|gm|gram|kg|ml|l|litre)", (net_quantity_str or "").lower())
        if match:
            val = float(match.group(1))
            unit = match.group(2)
            # Convert to grams or ml
            norm_val = val * 1000 if unit in ["kg", "l", "litre"] else val

            if norm_val <= 10.0 and product_type != "tobacco":
                return True, "LM-EX-001 (Small Package <= 10g/10ml)"
            if norm_val > 25000.0:
                return True, "LM-PC-003 (Bulk Package > 25kg/25L)"

        return False, None

    def evaluate_compliance(self, extracted_fields: Dict[str, Any], previous_offence_count: int = 0) -> Dict[str, Any]:
        """
        Evaluates the extracted 9 mandatory fields:
        1. mrp
        2. net_quantity
        3. manufacturing_date
        4. expiry_date
        5. manufacturer_name_address
        6. consumer_care
        7. country_of_origin
        8. unit_sale_price
        9. generic_name
        """
        mrp = str(extracted_fields.get("mrp") or "")
        net_qty = str(extracted_fields.get("net_quantity") or "")
        mfg_date = str(extracted_fields.get("manufacturing_date") or "")
        exp_date = str(extracted_fields.get("expiry_date") or "")
        mfg_addr = str(extracted_fields.get("manufacturer_name_address") or "")
        consumer_care = str(extracted_fields.get("consumer_care") or "")
        origin = str(extracted_fields.get("country_of_origin") or "")
        usp = str(extracted_fields.get("unit_sale_price") or "")
        generic_name = str(extracted_fields.get("generic_name") or "")

        # 1. Check exemptions first
        is_exempt, exemption_reason = self.check_exemption(net_qty)
        if is_exempt:
            return {
                "status": "COMPLIANT_EXEMPT",
                "is_exempt": True,
                "exemption_reason": exemption_reason,
                "violations": [],
                "action": "NO_ACTION_REQUIRED"
            }

        violations = []

        # 2. Check MRP (LM-PC-011)
        if not mrp or not any(k in mrp.lower() for k in ["rs", "₹", "mrp"]):
            violations.append({
                "rule_id": "LM-PC-011",
                "title": "Missing Maximum Retail Price (MRP)",
                "description": "Mandatory MRP declaration inclusive of all taxes missing or non-compliant under Rule 6(1)(e).",
                "section": "Section 36(1) read with Rule 6(1)(e)",
                "severity": "high"
            })

        # 3. Check Net Quantity (LM-PC-009)
        if not net_qty or not re.search(r"\d+\s*(g|kg|ml|l|n|piece|pair|set)", net_qty.lower()):
            violations.append({
                "rule_id": "LM-PC-009",
                "title": "Missing or Non-standard Net Quantity",
                "description": "Statutory Net Quantity declaration in metric SI units missing under Rule 6(1)(c) & Rules 11-13.",
                "section": "Section 36(1) read with Rule 6(1)(c)",
                "severity": "high"
            })

        # 4. Check Mfg Date (LM-PC-010) - Rule 6(1)(d) Explanation I allows words or numerals
        has_valid_mfg = bool(re.search(r"\d{1,2}[/-]\d{2,4}", mfg_date) or re.search(r"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*\d{2,4}", mfg_date, re.IGNORECASE))
        if not mfg_date or not has_valid_mfg:
            violations.append({
                "rule_id": "LM-PC-010",
                "title": "Missing Month & Year of Manufacture",
                "description": "Month and Year of manufacture missing under Rule 6(1)(d).",
                "section": "Section 36(1) read with Rule 6(1)(d)",
                "severity": "medium"
            })

        # 5. Check Expiry Date & Expired Goods (Rule 6(1)(d) & Consumer Protection)
        expiry_applicable = extracted_fields.get("expiry_applicable", True)
        is_expired = extracted_fields.get("is_expired", False)
        category = extracted_fields.get("category", "GENERAL")
        exemptions_detected = []

        if is_expired:
            violations.append({
                "rule_id": "LM-PC-EXP",
                "title": "Sale of Expired Pre-Packaged Commodity",
                "description": f"The package expiry date ('{exp_date}') has lapsed. Selling expired pre-packaged goods is strictly prohibited under Rule 6(1)(d) read with Section 36(1) of Legal Metrology Act, 2009.",
                "section": "Section 36(1) read with Rule 6(1)(d)",
                "severity": "critical"
            })
        elif not expiry_applicable or category in ["DURABLE_HARDWARE_GLASSWARE", "ELECTRONICS", "TEXTILE"]:
            exemptions_detected.append(f"Rule 6(1)(d): Expiry date exempted for non-perishable category '{category}' (Glassware/Hardware/Electronics)")
        else:
            # Perishable goods require expiry or best before
            has_valid_exp = bool(exp_date and len(exp_date.strip()) > 3)
            if not has_valid_exp:
                violations.append({
                    "rule_id": "LM-PC-014",
                    "title": "Missing Expiry / Best Before Date",
                    "description": "Perishable commodity missing mandatory Expiry / 'Best Before' / 'Use By' declaration under Rule 6(1)(d).",
                    "section": "Section 36(1) read with Rule 6(1)(d)",
                    "severity": "high"
                })

        # 6. Check Manufacturer details & PIN code (LM-PC-006)
        if not mfg_addr or len(mfg_addr.strip()) < 10:
            violations.append({
                "rule_id": "LM-PC-006",
                "title": "Incomplete Manufacturer / Packer Address",
                "description": "Complete name and postal address (with postal PIN code) of manufacturer/packer missing under Rule 6(1)(a) & Rule 10.",
                "section": "Section 36(1) read with Rule 6(1)(a)",
                "severity": "high"
            })

        # 7. Check Consumer Care Details (LM-PC-012)
        if not consumer_care or not any(c in consumer_care.lower() for c in ["@", "1800", "tel", "phone", "email", "care"]):
            violations.append({
                "rule_id": "LM-PC-012",
                "title": "Missing Consumer Care Redressal Details",
                "description": "Statutory grievance redressal officer contact (telephone/email) missing under Rule 6(2).",
                "section": "Section 36(1) read with Rule 6(2)",
                "severity": "medium"
            })

        # 8. Check Country of Origin (LM-PC-007)
        if not origin:
            violations.append({
                "rule_id": "LM-PC-007",
                "title": "Missing Country of Origin",
                "description": "Declaration of Country of Origin is mandatory under Rule 6(1)(aa).",
                "section": "Section 36(1) read with Rule 6(1)(aa)",
                "severity": "medium"
            })

        # 9. Check Unit Sale Price (LM-PC-016)
        if not usp and ("kg" in net_qty.lower() or "l" in net_qty.lower() or "g" in net_qty.lower()):
            violations.append({
                "rule_id": "LM-PC-016",
                "title": "Missing Unit Sale Price (USP)",
                "description": "Mandatory unit sale price (₹ per g/kg or ₹ per ml/L) missing under Rule 6(11) amendment.",
                "section": "Section 36(1) read with Rule 6(11)",
                "severity": "high"
            })

        # 10. Check Generic Name (LM-PC-008)
        if not generic_name:
            violations.append({
                "rule_id": "LM-PC-008",
                "title": "Missing Generic / Common Name",
                "description": "Common or generic name of commodity missing under Rule 6(1)(b).",
                "section": "Section 36(1) read with Rule 6(1)(b)",
                "severity": "medium"
            })

        is_compliant = len(violations) == 0
        is_second_offence = previous_offence_count > 0

        # Determine compounding vs court prosecution
        if is_second_offence:
            action = "MANDATORY_COURT_PROSECUTION"
            fine_text = "Fine up to ₹50,000 for 2nd offence (Section 49 mandates court trial)"
            compoundable = False
        elif not is_compliant:
            action = "COMPOUNDING_OR_IMPROVEMENT_NOTICE"
            fine_text = "Statutory fine up to ₹25,000 (Compoundable under Section 48(1) / Rule 32A table: ₹5,000 for retail, ₹25,000 for manufacturer)"
            compoundable = True
        else:
            action = "COMPLIANT"
            fine_text = "None (Fully Compliant)"
            compoundable = False

        return {
            "status": "COMPLIANT" if is_compliant else "NON_COMPLIANT",
            "is_exempt": False,
            "violations_count": len(violations),
            "violations": violations,
            "exemptions_detected": exemptions_detected,
            "is_second_offence": is_second_offence,
            "action": action,
            "fine_summary": fine_text,
            "compoundable": compoundable,
            "governing_section": "Section 49 (Court Prosecution)" if is_second_offence else "Section 36(1) read with Section 48 (Compounding)"
        }
