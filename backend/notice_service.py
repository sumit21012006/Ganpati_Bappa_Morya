import os
import re
from typing import Dict, Any, List, Optional
import docx

class NoticeGenerator:
    """
    Automated Legal Metrology Notice & Order Generator
    Generates authentic government documents directly from official docx templates:
    1. Compounding Order (Compounding_Order_Template.docx)
    2. Improvement Notice (Improvement_Notice_Template.docx)
    3. Spot Panchanama (Panchanama_Template.docx)
    4. Seizure Bill (Seizure_Bill_English_Template.docx)
    """

    def __init__(self, template_dir: str = "Notices_Template"):
        self.template_dir = template_dir
        self.output_dir = os.path.join(template_dir, "generated")
        os.makedirs(self.output_dir, exist_ok=True)

    def _replace_text_in_doc(self, doc: docx.Document, replacements: Dict[str, str]):
        """Replace placeholders in paragraphs and tables cleanly."""
        for p in doc.paragraphs:
            for k, v in replacements.items():
                if k in p.text:
                    p.text = p.text.replace(k, str(v))
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    for k, v in replacements.items():
                        if k in cell.text:
                            cell.text = cell.text.replace(k, str(v))

    def generate_compounding_order(self, data: Dict[str, Any]) -> str:
        """
        Generates Government of Maharashtra Compounding Order.
        Template: Compounding_Order_Template.docx
        """
        template_path = os.path.join(self.template_dir, "Compounding_Order_Template.docx")
        doc = docx.Document(template_path)

        replacements = {
            "{{SEIZURE_RECEIPT_NO}}": data.get("seizure_receipt_no", "SZ-2026-MH-0842"),
            "{{SEIZURE_DATE}}": data.get("seizure_date", "07/09/2026"),
            "{{PANCHNAMA_DATE}}": data.get("panchanama_date", "07/09/2026"),
            "{{COMPOUNDING_NOTICE_NO}}": data.get("compounding_notice_no", "CN-2026-0912"),
            "{{COMPOUNDING_NOTICE_DATE}}": data.get("compounding_notice_date", "07/09/2026"),
            "{{REQUEST_LETTER_DATE}}": data.get("request_letter_date", "07/09/2026"),
            "{{INSPECTOR_OFFICE}}": data.get("inspector_office", "Mumbai Division-II"),
            "{{PROPOSAL_DATE}}": data.get("proposal_date", "07/09/2026"),
            "{{PERSON_NAME}}": data.get("person_name", "Shri R. K. Gupta"),
            "{{PERSON_ADDRESS}}": data.get("person_address", "Shop No 14, APMC Market, Vashi"),
            "{{PERSON_DESIGNATION}}": data.get("person_designation", "Proprietor"),
            "{{FIRM_NAME}}": data.get("firm_name", "M/s. Gupta Retail LLP"),
            "{{FIRM_ADDRESS}}": data.get("firm_address", "Plot 18, Sector 19, Vashi, Navi Mumbai"),
            "{{OFFENCE_SECTIONS_AND_RULES}}": data.get("offence_sections_and_rules", "Section 36(1) read with Rule 6(1)(e) & Rule 6(11) of PCR 2011"),
            "{{AUTHORITY_ORDER_NO}}": data.get("authority_order_no", "CLM/MH/2026/410"),
            "{{AUTHORITY_ORDER_DATE}}": data.get("authority_order_date", "01/01/2026"),
            "{{ORDERING_OFFICER_NAME}}": data.get("ordering_officer_name", "Dr. S. K. Deshmukh"),
            "{{ORDERING_OFFICER_DESIGNATION}}": data.get("ordering_officer_designation", "Deputy Controller of Legal Metrology"),
            "{{TOTAL_COMPOUNDING_AMOUNT}}": str(data.get("compounding_amount", "25,000")),
            "{{AMOUNT_IN_WORDS}}": data.get("amount_in_words", "Twenty Five Thousand"),
            "{{GRAS_RECEIPT_HEAD}}": data.get("gras_receipt_head", "0435 - Other Agricultural Programmes / Legal Metrology Receipts"),
            "{{PAYMENT_DAYS}}": str(data.get("payment_days", "30")),
            "{{ACCOUNT_OFFICER_DESIGNATION}}": data.get("account_officer_designation", "Assistant Controller of Legal Metrology"),
            "{{COMPOUNDING_ORDER_NO}}": data.get("compounding_order_no", f"LM/CO/2026/{data.get('case_id', '9041')}"),
            "{PERSON_OR_FIRM_1}": data.get("firm_name", "M/s. Gupta Retail LLP"),
            "{AMOUNT_1}": str(data.get("compounding_amount", "25,000")),
            "{PERSON_OR_FIRM_2}": "—",
            "{AMOUNT_2}": "0.00",
            "{PERSON_OR_FIRM_3}": "—",
            "{AMOUNT_3}": "0.00",
            "{PERSON_OR_FIRM_4}": "—",
            "{AMOUNT_4}": "0.00",
            "{PERSON_OR_FIRM_5}": "—",
            "{AMOUNT_5}": "0.00",
        }

        self._replace_text_in_doc(doc, replacements)
        file_name = f"Compounding_Order_{data.get('case_id', '9041')}.docx"
        output_path = os.path.join(self.output_dir, file_name)
        doc.save(output_path)
        return output_path

    def generate_improvement_notice(self, data: Dict[str, Any]) -> str:
        """
        Generates Statutory Improvement Notice (Under Section 15(6) / Rule 20(1)(ii)).
        Template: Improvement_Notice_Template.docx
        """
        template_path = os.path.join(self.template_dir, "Improvement_Notice_Template.docx")
        doc = docx.Document(template_path)

        violations_text = "\n".join([
            f"{idx+1}. {v.get('description', '')} (Violation {v.get('section', 'Section 36(1)')} of the Act / Rule {v.get('rule', 'Rule 6')})"
            for idx, v in enumerate(data.get("violations", []))
        ]) or "1. Failure to declare Unit Sale Price & MRP Alteration (Section 36(1) read with Rule 6(11) of PCR 2011)"

        replacements = {
            "OFFICE OF THE LEGAL METROLOGY OFFICER, ____________": f"OFFICE OF THE LEGAL METROLOGY OFFICER, {data.get('jurisdiction', 'MUMBAI CIRCLE')}",
            "Notice No.: __________________": f"Notice No.: NOT-IN-{data.get('notice_id', '2026-0812')}",
            "Date: __________________": f"Date: {data.get('date', '07/09/2026')}",
            "________________________________________________________________________________\n________________________________________________________________________________": f"To: {data.get('firm_name', 'M/s Retail Enterprise')}\nAddress: {data.get('firm_address', 'Mumbai, Maharashtra')}",
            "business premises on __________________": f"business premises on {data.get('inspection_date', '07/09/2026')}",
            "within _____ (_____) days": f"within {data.get('rectification_days', 15)} (Fifteen) days",
        }

        self._replace_text_in_doc(doc, replacements)

        # Inject violations list
        for p in doc.paragraphs:
            if "1.    __________________________________" in p.text:
                p.text = violations_text
            elif "2.    __________________________________" in p.text or "3.    __________________________________" in p.text:
                p.text = ""

        file_name = f"Improvement_Notice_{data.get('notice_id', '2026-0812')}.docx"
        output_path = os.path.join(self.output_dir, file_name)
        doc.save(output_path)
        return output_path

    def generate_panchanama(self, data: Dict[str, Any]) -> str:
        """
        Generates Spot Panchanama Record (CrPC Section 100 / LM Act Section 15(4)).
        Template: Panchanama_Template.docx
        """
        template_path = os.path.join(self.template_dir, "Panchanama_Template.docx")
        doc = docx.Document(template_path)

        replacements = {
            "Name of the Establishment/Trader: ________________________________________________________": f"Name of the Establishment/Trader: {data.get('firm_name', 'M/s Retail Stores')}",
            "Address: ____________________________________________________________________________________": f"Address: {data.get('firm_address', 'Pune, Maharashtra')}",
            "1. Description of Commodity: ______________________________________________________________": f"1. Description of Commodity: {data.get('product_name', 'Pre-packaged Atta 5kg')}",
            "2. Batch No. / Manufacturing Date: _________________________________________________________": f"2. Batch No. / Manufacturing Date: {data.get('batch_number', 'BATCH-88A')} / {data.get('mfg_date', '08/2026')}",
            "3. Nature of Offence: _______________________________________________________________________": f"3. Nature of Offence: {data.get('violation_summary', 'Missing Unit Sale Price and Deficit Net Quantity')}",
            "The Legal Metrology Officer has seized ______ number of packages/samples": f"The Legal Metrology Officer has seized {data.get('seized_count', '6')} number of packages/samples",
        }

        self._replace_text_in_doc(doc, replacements)
        file_name = f"Panchanama_{data.get('case_id', '2026-0812')}.docx"
        output_path = os.path.join(self.output_dir, file_name)
        doc.save(output_path)
        return output_path
