import os
import re
from datetime import datetime, timezone, timedelta

IST = timezone(timedelta(hours=5, minutes=30), name="IST")
from typing import Dict, Any, List, Optional
import docx
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image as RLImage, KeepTogether
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

class NoticeGenerator:
    """
    Automated Legal Metrology Notice & Order Generator
    Generates authentic government documents in both:
    1. High-Fidelity Official PDF (matching Compounding_SAMPLE_GENERATED.pdf)
    2. Official Editable Word DOCX (from Government of India / Maharashtra templates)
    
    Document Types:
    - Compounding Order (Compounding_Order_Template.docx)
    - Statutory Improvement Notice (Improvement_Notice_Template.docx)
    - Spot Panchanama (Panchanama_Template.docx)
    - Seizure Bill / Notice (Seizure_Bill_English_Template.docx)
    """

    def __init__(self, template_dir: str = "Notices_Template"):
        self.template_dir = template_dir
        self.output_dir = os.path.join(template_dir, "generated")
        os.makedirs(self.output_dir, exist_ok=True)
        self.emblem_path = os.path.join(template_dir, "gov_emblem.png")
        if not os.path.exists(self.emblem_path):
            alt_emblem = os.path.join(template_dir, "emblem_0_0.png")
            if os.path.exists(alt_emblem):
                self.emblem_path = alt_emblem

    # -------------------------------------------------------------------------
    # Helper: Word DOCX text replacement
    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # Helper: Canvas Page Border & Official Footer
    # -------------------------------------------------------------------------
    def _draw_official_frame(self, canv: canvas.Canvas, doc, total_pages: int = 1, is_signed: bool = False, signer_name: str = "", sign_date: str = "", signature_img: Optional[str] = None):
        """Draws the authentic Government single rectangular border and footer."""
        canv.saveState()
        # Page border matching reference PDF (18.5pt margin from edges)
        canv.setStrokeColor(colors.black)
        canv.setLineWidth(1.0)
        canv.rect(18.5, 18.5, 595.0 - 37.0, 842.0 - 37.0)

        # Footer
        canv.setFont("Times-Roman", 9)
        canv.drawString(24, 25, f"Page {canv._pageNumber} of {total_pages}")
        canv.setFont("Helvetica", 7.5)
        canv.drawString(90, 25, "Note : This document is digitally signed, manual signature not required")

        # Digital signature block & drawn signature on the last page if signed
        if is_signed and canv._pageNumber == total_pages:
            self._draw_digital_signature_stamp(canv, signer_name or "LEGAL METROLOGY OFFICER", sign_date)
            if signature_img and os.path.exists(signature_img):
                try:
                    # Draw inspector drawn signature above the title
                    canv.drawImage(signature_img, 410, 85, width=120, height=45, preserveAspectRatio=True, mask='auto')
                except Exception:
                    pass

        canv.restoreState()

    def _draw_digital_signature_stamp(self, canv: canvas.Canvas, signer_name: str, sign_date: str):
        """Draws the official green-tick digital verification stamp at bottom right."""
        x = 440
        y = 22
        # Green tick mark
        canv.setFillColor(colors.HexColor("#1b7e36"))
        p = canv.beginPath()
        p.moveTo(x + 5, y + 14)
        p.lineTo(x + 14, y + 4)
        p.lineTo(x + 32, y + 26)
        p.lineTo(x + 28, y + 28)
        p.lineTo(x + 14, y + 10)
        p.lineTo(x + 8, y + 16)
        p.close()
        canv.drawPath(p, fill=1, stroke=0)

        # Digital signature text
        canv.setFillColor(colors.black)
        canv.setFont("Helvetica-Bold", 6.5)
        canv.drawString(x + 36, y + 22, f"Digitally signed by {signer_name.upper()}")
        canv.setFont("Helvetica", 6.0)
        date_str = sign_date or datetime.now(IST).strftime("%Y.%m.%d %H:%M:%S +05:30")
        canv.drawString(x + 36, y + 12, f"Date: {date_str}")
        canv.drawString(x + 36, y + 4, "Verified by Legal Metrology Organisation")

    # =========================================================================
    # 1. COMPOUNDING ORDER (PDF & DOCX)
    # =========================================================================
    def generate_compounding_order(self, data: Dict[str, Any], is_signed: bool = False, signer_name: str = "", signature_img: Optional[str] = None) -> Dict[str, str]:
        """
        Generates Government of Maharashtra Compounding Order matching Compounding_SAMPLE_GENERATED.pdf.
        Returns paths to both .docx and .pdf files.
        """
        case_id = data.get("case_id", "9041")
        order_no = data.get("compounding_order_no", f"JCLM/Nagpur/{case_id}/M1/54902/2026-27")
        now_local = datetime.now(IST)
        date_str = data.get("date", now_local.strftime("%d/%m/%Y"))
        time_str = data.get("time", now_local.strftime("%I:%M %p"))
        stamp_str = data.get("timestamp", now_local.strftime("%Y.%m.%d %H:%M:%S +05:30"))
        firm_name = data.get("firm_name", "M/s. Gupta Retail LLP")
        firm_address = data.get("firm_address", "Plot 18, Sector 19, Vashi, Navi Mumbai")
        person_name = data.get("person_name", "Shri R. K. Gupta")
        person_designation = data.get("person_designation", "Proprietor")
        amount = str(data.get("compounding_amount", "25,000"))
        amount_words = data.get("amount_in_words", "Twenty Five Thousand")
        officer_name = data.get("ordering_officer_name", signer_name or "PANDURANG MADHAVRAO BIRADAR")
        officer_desig = data.get("ordering_officer_designation", "Joint Controller of Legal Metrology")
        seizure_no = data.get("seizure_receipt_no", "SZ-2026-MH-0842")
        sections = data.get("offence_sections_and_rules", "S. 18(1) r/w R 6(1)(d), S. 18(1) r/w R 6(1)(e) and S. 36(1) of PCR 2011")

        # 1. Generate DOCX
        docx_template = os.path.join(self.template_dir, "Compounding_Order_Template.docx")
        docx_output = os.path.join(self.output_dir, f"Compounding_Order_{case_id}.docx")
        if os.path.exists(docx_template):
            doc = docx.Document(docx_template)
            replacements = {
                "{{SEIZURE_RECEIPT_NO}}": seizure_no,
                "{{SEIZURE_DATE}}": date_str,
                "{{PANCHNAMA_DATE}}": date_str,
                "{{COMPOUNDING_NOTICE_NO}}": f"CN-2026-{case_id}",
                "{{COMPOUNDING_NOTICE_DATE}}": date_str,
                "{{REQUEST_LETTER_DATE}}": date_str,
                "{{INSPECTOR_OFFICE}}": "ILM, Division-IV",
                "{{PROPOSAL_DATE}}": date_str,
                "{{PERSON_NAME}}": person_name,
                "{{PERSON_ADDRESS}}": firm_address,
                "{{PERSON_DESIGNATION}}": person_designation,
                "{{FIRM_NAME}}": firm_name,
                "{{FIRM_ADDRESS}}": firm_address,
                "{{OFFENCE_SECTIONS_AND_RULES}}": sections,
                "{{AUTHORITY_ORDER_NO}}": "CLM/MH/2026/410",
                "{{AUTHORITY_ORDER_DATE}}": "29th July, 2011",
                "{{ORDERING_OFFICER_NAME}}": officer_name,
                "{{ORDERING_OFFICER_DESIGNATION}}": officer_desig,
                "{{TOTAL_COMPOUNDING_AMOUNT}}": amount,
                "{{AMOUNT_IN_WORDS}}": amount_words,
                "{{GRAS_RECEIPT_HEAD}}": "1475-other General Economic Services, (106) fees for stamping weights and measures",
                "{{PAYMENT_DAYS}}": "15",
                "{{ACCOUNT_OFFICER_DESIGNATION}}": "Inspector of Legal Metrology",
                "{{COMPOUNDING_ORDER_NO}}": order_no,
                "{PERSON_OR_FIRM_1}": firm_name,
                "{AMOUNT_1}": amount,
            }
            self._replace_text_in_doc(doc, replacements)
            doc.save(docx_output)

        # 2. Generate PDF with ReportLab (2-Page official format matching reference)
        pdf_output = os.path.join(self.output_dir, f"Compounding_Order_{case_id}.pdf")
        doc_pdf = SimpleDocTemplate(
            pdf_output,
            pagesize=A4,
            leftMargin=30,
            rightMargin=30,
            topMargin=26,
            bottomMargin=40
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle('HeaderTitle', fontName='Helvetica-Bold', fontSize=10.5, leading=13, alignment=1)
        sub_style = ParagraphStyle('HeaderSub', fontName='Helvetica-Bold', fontSize=10, leading=12, alignment=1)
        body_style = ParagraphStyle('BodyTextNorm', fontName='Times-Roman', fontSize=10, leading=14, alignment=4)
        body_bold = ParagraphStyle('BodyTextBold', fontName='Times-Bold', fontSize=10, leading=14)
        small_style = ParagraphStyle('SmallText', fontName='Helvetica', fontSize=8.5, leading=11)

        story = []

        # Emblem
        if os.path.exists(self.emblem_path):
            story.append(RLImage(self.emblem_path, width=65, height=68))
        story.append(Spacer(1, 4))

        story.append(Paragraph("GOVERNMENT OF MAHARASHTRA", title_style))
        story.append(Paragraph("LEGAL METROLOGY ORGANISATION", title_style))
        story.append(Spacer(1, 3))
        story.append(Paragraph("<u>COMPOUNDING ORDER</u>", title_style))
        story.append(Paragraph("<u>THE LEGAL METROLOGY ACT, 2009</u>", sub_style))
        story.append(Spacer(1, 8))

        # Order No & Date table
        ref_data = [
            [Paragraph(f"<b>Compounding Order No:</b> &nbsp; {order_no}", small_style), Paragraph(f"<b>Date:</b> &nbsp; {date_str}", small_style)],
            [Paragraph(f"1) Seizure Receipt no: <b>{seizure_no}</b> &nbsp; Date: <b>{date_str}</b>", small_style), Paragraph(f"Panchanama date : <b>{date_str}</b>", small_style)],
            [Paragraph(f"2) Compounding notice No: <b>CN-{case_id}</b> &nbsp; Date: <b>{date_str}</b>", small_style), Paragraph("", small_style)],
            [Paragraph(f"3) Compounding Request Letter Date: <b>{date_str}</b>", small_style), Paragraph("", small_style)],
            [Paragraph(f"4) Proposal of Inspector of Legal Metrology ILM Division Date: <b>{date_str}</b>", small_style), Paragraph("", small_style)],
        ]
        t_ref = Table(ref_data, colWidths=[330, 205])
        t_ref.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('BOTTOMPADDING', (0,0), (-1,-1), 2),
            ('TOPPADDING', (0,0), (-1,-1), 1),
        ]))
        story.append(t_ref)
        story.append(Spacer(1, 6))

        story.append(Paragraph("<b><u>ORDER</u></b>", ParagraphStyle('OrderH', fontName='Helvetica-Bold', fontSize=9.5, alignment=1)))
        story.append(Spacer(1, 6))

        # Order Body
        order_p1 = (
            f"Whereas <b>{person_name}</b>, {firm_address}, <b>{person_designation}</b> of <b>{firm_name}</b> and, "
            f"whereas the said <b>{person_name}</b> has agreed to compound the offence(s) <b>{sections}</b>, "
            f"punishable under Section 36(1) of The Legal Metrology Act, 2009 / The Legal Metrology (Packaged Commodities) "
            f"Rules, 2011 / The Maharashtra Legal Metrology (Enforcement) Rules, 2011."
        )
        story.append(Paragraph(order_p1, body_style))
        story.append(Spacer(1, 10))

        order_p2 = (
            f"Therefore, in exercise of the powers u/s 48 (3) of The Legal Metrology Act, 2009 and Rule 25 of the "
            f"Maharashtra Legal Metrology (Enforcement) Rules, 2011, and powers conferred upon me vide order "
            f"LMO/2010/410/C.R.175 (Part-2)/C.P.4 dated 29th July, 2011 by the Controller of Legal Metrology, "
            f"Maharashtra State, Mumbai. I <b>{officer_name}</b>, <b>{officer_desig}</b> hereby determine the amount "
            f"of compounding for the above offence of <b>Rs. {amount}.00</b> (Rupees <b>{amount_words} Only</b>) "
            f"and direct <b>{person_name}</b>, {firm_address} of <b>{firm_name}</b> to deposit the said amount to the "
            f"Government, online by the GRAS portal under receipt head 1475-other General Economic Services, (106) fees for "
            f"stamping weights and measures, other fees, fine and forfeitures, within 15 days from receipt of this order in Account "
            f"of Inspector of Legal Metrology."
        )
        story.append(Paragraph(order_p2, body_style))
        story.append(Spacer(1, 18))

        # Page break for Page 2
        from reportlab.platypus import PageBreak
        story.append(PageBreak())

        # Page 2 content
        story.append(Paragraph(f"<b>Compounding Order No:</b> &nbsp; {order_no}", small_style))
        story.append(Spacer(1, 6))
        story.append(Paragraph("The details of the compounding fees for the firm and persons concerned are as follows:", body_style))
        story.append(Spacer(1, 6))

        fee_data = [
            ["Sr.", "Person / Establishment", "Compounding Amount"],
            ["01", f"Name and Address of the Firm: {firm_name}, {firm_address}", f"Rs. {amount}.00"],
            ["02", f"{person_name} ({person_designation})", "Included Above"],
        ]
        t_fee = Table(fee_data, colWidths=[35, 380, 120])
        t_fee.setStyle(TableStyle([
            ('GRID', (0,0), (-1,-1), 0.5, colors.grey),
            ('BACKGROUND', (0,0), (-1,0), colors.whitesmoke),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 8.5),
            ('ALIGN', (0,0), (0,-1), 'CENTER'),
            ('ALIGN', (2,0), (2,-1), 'RIGHT'),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 4),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        story.append(t_fee)
        story.append(Spacer(1, 10))

        story.append(Paragraph("<b>After the Amount of composition is realized, the offence shall be deemed to be discharged.</b>", body_style))
        story.append(Spacer(1, 8))

        story.append(Paragraph("<b>Copy to:</b>", body_bold))
        story.append(Paragraph(f"1) {firm_name}, {firm_address}", body_style))
        story.append(Paragraph(f"2) Inspector of Legal Metrology, Division Enforcement", body_style))
        story.append(Spacer(1, 4))
        instructions = [
            "a) He/She should serve the order to the person(s) and thereafter upload particulars about the defaced challan once compounding fee is credited.",
            "b) After deposition of compounding fee: i) The seized packages should be returned immediately with an undertaking to rectify them; ii) Seized unverified measures returned for stamping within 15 days; iii) Non-standard measures shall be forfeited to Government.",
            "c) In the event of non-payment of compounding amount within the stipulated period, a complaint shall be filed in the court of law before expiry of limitation period."
        ]
        for inst in instructions:
            story.append(Paragraph(inst, small_style))
            story.append(Spacer(1, 3))

        story.append(Spacer(1, 25))
        story.append(Paragraph("<b>Signature of the LMO</b><br/>Legal Metrology Officer", ParagraphStyle('LMO', fontName='Helvetica-Bold', fontSize=9, alignment=2)))

        def page_decorator(canv, doc):
            self._draw_official_frame(canv, doc, total_pages=2, is_signed=is_signed, signer_name=officer_name, sign_date=stamp_str, signature_img=signature_img)

        doc_pdf.build(story, onFirstPage=page_decorator, onLaterPages=page_decorator)

        return {
            "docx": docx_output,
            "pdf": pdf_output,
            "filename_docx": os.path.basename(docx_output),
            "filename_pdf": os.path.basename(pdf_output)
        }

    # =========================================================================
    # 2. IMPROVEMENT NOTICE (PDF & DOCX)
    # =========================================================================
    def generate_improvement_notice(self, data: Dict[str, Any], is_signed: bool = False, signer_name: str = "", signature_img: Optional[str] = None) -> Dict[str, str]:
        """
        Generates Statutory Improvement Notice (Under Section 15(6) / Rule 20(1)(ii)).
        Returns paths to both .docx and .pdf files.
        """
        notice_id = data.get("notice_id", data.get("case_id", "2026-0812"))
        notice_no = f"NOT-IN-{notice_id}"
        now_local = datetime.now(IST)
        date_str = data.get("date", now_local.strftime("%d/%m/%Y"))
        time_str = data.get("time", now_local.strftime("%I:%M %p"))
        stamp_str = data.get("timestamp", now_local.strftime("%Y.%m.%d %H:%M:%S +05:30"))
        firm_name = data.get("firm_name", "M/s Retail Enterprise")
        firm_address = data.get("firm_address", "Mumbai, Maharashtra")
        jurisdiction = data.get("jurisdiction", "MUMBAI CIRCLE DIVISION-II")
        rect_days = str(data.get("rectification_days", 15))
        officer_name = signer_name or data.get("ordering_officer_name", "LEGAL METROLOGY OFFICER")

        violations = data.get("violations", [])
        if not violations:
            violations_text_list = [
                "Absence of Mandatory Unit Sale Price (Rule 6(11) / Section 36(1))",
                "Non-compliant Net Quantity Declaration (Rule 12 / Section 36(1))",
                "Missing Customer Care / Importer Details (Rule 6(1)(d))"
            ]
        else:
            violations_text_list = [
                f"{v.get('description', v.get('title', 'Statutory Violation'))} "
                f"({v.get('legal_section', v.get('section', 'Section 36(1)'))})"
                for v in violations
            ]

        # 1. DOCX
        docx_template = os.path.join(self.template_dir, "Improvement_Notice_Template.docx")
        docx_output = os.path.join(self.output_dir, f"Improvement_Notice_{notice_id}.docx")
        if os.path.exists(docx_template):
            doc = docx.Document(docx_template)
            replacements = {
                "OFFICE OF THE LEGAL METROLOGY OFFICER, ____________": f"OFFICE OF THE LEGAL METROLOGY OFFICER, {jurisdiction}",
                "Notice No.: __________________": f"Notice No.: {notice_no}",
                "Date: __________________": f"Date: {date_str}",
                "________________________________________________________________________________\n________________________________________________________________________________": f"To: {firm_name}\nAddress: {firm_address}",
                "business premises on __________________": f"business premises on {date_str}",
                "within _____ (_____) days": f"within {rect_days} (Fifteen) days",
            }
            self._replace_text_in_doc(doc, replacements)
            # Inject violations
            viol_bullet = "\n".join([f"{i+1}. {txt}" for i, txt in enumerate(violations_text_list)])
            for p in doc.paragraphs:
                if "1.    __________________________________" in p.text:
                    p.text = viol_bullet
                elif "2.    __________________________________" in p.text or "3.    __________________________________" in p.text:
                    p.text = ""
            doc.save(docx_output)

        # 2. PDF with ReportLab
        pdf_output = os.path.join(self.output_dir, f"Improvement_Notice_{notice_id}.pdf")
        doc_pdf = SimpleDocTemplate(
            pdf_output,
            pagesize=A4,
            leftMargin=30,
            rightMargin=30,
            topMargin=26,
            bottomMargin=40
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle('HeaderTitle', fontName='Helvetica-Bold', fontSize=10.5, leading=13, alignment=1)
        sub_style = ParagraphStyle('HeaderSub', fontName='Helvetica-Bold', fontSize=9.5, leading=12, alignment=1)
        body_style = ParagraphStyle('BodyTextNorm', fontName='Times-Roman', fontSize=10, leading=14, alignment=4)
        small_style = ParagraphStyle('SmallText', fontName='Helvetica', fontSize=8.5, leading=11)

        story = []
        if os.path.exists(self.emblem_path):
            story.append(RLImage(self.emblem_path, width=65, height=68))
        story.append(Spacer(1, 4))

        story.append(Paragraph("GOVERNMENT OF MAHARASHTRA", title_style))
        story.append(Paragraph("LEGAL METROLOGY ORGANISATION", title_style))
        story.append(Paragraph(f"OFFICE OF THE LEGAL METROLOGY OFFICER, {jurisdiction}", sub_style))
        story.append(Spacer(1, 4))
        story.append(Paragraph("<u>IMPROVEMENT NOTICE</u>", title_style))
        story.append(Paragraph("<u>[Under Section 15(6) of the Legal Metrology Act, 2009]</u>", sub_style))
        story.append(Spacer(1, 10))

        meta_table = [
            [Paragraph(f"<b>Notice No.:</b> {notice_no}", small_style), Paragraph(f"<b>Date:</b> {date_str}", small_style)]
        ]
        t_meta = Table(meta_table, colWidths=[330, 205])
        story.append(t_meta)
        story.append(Spacer(1, 8))

        story.append(Paragraph(f"<b>To,</b><br/><b>{firm_name}</b><br/>{firm_address}", body_style))
        story.append(Spacer(1, 8))

        p_preamble = (
            f"Whereas, during statutory inspection of your business establishment conducted on <b>{date_str}</b> "
            f"under the powers conferred by Section 15 of the Legal Metrology Act, 2009, the following non-compliances "
            f"and irregularities were observed in the pre-packaged commodities offered for sale/storage:"
        )
        story.append(Paragraph(p_preamble, body_style))
        story.append(Spacer(1, 6))

        # Violations Table
        viol_rows = [["No.", "Description of Irregularity / Non-Compliance", "Statutory Provision"]]
        for idx, vtxt in enumerate(violations_text_list):
            viol_rows.append([str(idx + 1), vtxt, "LM Act 2009 / PCR 2011"])

        t_viol = Table(viol_rows, colWidths=[30, 380, 125])
        t_viol.setStyle(TableStyle([
            ('GRID', (0,0), (-1,-1), 0.5, colors.grey),
            ('BACKGROUND', (0,0), (-1,0), colors.whitesmoke),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 8.5),
            ('ALIGN', (0,0), (0,-1), 'CENTER'),
            ('TOPPADDING', (0,0), (-1,-1), 4),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        story.append(t_viol)
        story.append(Spacer(1, 10))

        directives = (
            f"You are hereby directed to take immediate corrective measures to rectify the above-mentioned irregularities "
            f"within <b>{rect_days} (Fifteen) days</b> from receipt of this notice. During this period, you are further instructed "
            f"to refrain from selling or distributing non-compliant packages until full rectification is confirmed.<br/><br/>"
            f"Take notice that failure to rectify within the stipulated period shall be deemed a willful offence punishable "
            f"under Section 36(1) and Section 48 of the Act, entailing prosecution and seizure of goods without further reference."
        )
        story.append(Paragraph(directives, body_style))
        story.append(Spacer(1, 30))

        story.append(Paragraph(f"<b>{officer_name}</b><br/>Inspector of Legal Metrology<br/>{jurisdiction}", ParagraphStyle('LMO', fontName='Helvetica-Bold', fontSize=9, alignment=2)))

        def page_decorator(canv, doc):
            self._draw_official_frame(canv, doc, total_pages=1, is_signed=is_signed, signer_name=officer_name, sign_date=stamp_str, signature_img=signature_img)

        doc_pdf.build(story, onFirstPage=page_decorator, onLaterPages=page_decorator)

        return {
            "docx": docx_output,
            "pdf": pdf_output,
            "filename_docx": os.path.basename(docx_output),
            "filename_pdf": os.path.basename(pdf_output)
        }

    # =========================================================================
    # 3. SEIZURE BILL / NOTICE (PDF & DOCX)
    # =========================================================================
    def generate_seizure_bill(self, data: Dict[str, Any], is_signed: bool = False, signer_name: str = "", signature_img: Optional[str] = None) -> Dict[str, str]:
        """
        Generates Government Seizure Bill / Receipt (Under Section 15 of Legal Metrology Act, 2009).
        Returns paths to both .docx and .pdf files.
        """
        case_id = data.get("case_id", "2026-SZ-01")
        receipt_no = f"SZ-MH-{case_id}"
        now_local = datetime.now(IST)
        date_str = data.get("date", now_local.strftime("%d/%m/%Y"))
        time_str = data.get("time", now_local.strftime("%I:%M %p"))
        stamp_str = data.get("timestamp", now_local.strftime("%Y.%m.%d %H:%M:%S +05:30"))
        firm_name = data.get("firm_name", "M/s Gupta Retail LLP")
        firm_address = data.get("firm_address", "APMC Market, Vashi, Navi Mumbai")
        officer_name = signer_name or data.get("ordering_officer_name", "LEGAL METROLOGY OFFICER")
        commodity = data.get("product_name", "Pre-packaged Commodity Packages")
        qty = str(data.get("seized_count", data.get("quantity", "6 packages")))
        reason = data.get("reason", "Contravention of Section 18(1) & 36(1) — Missing MRP & Non-standard Net Quantity")

        # 1. DOCX
        docx_template = os.path.join(self.template_dir, "Seizure_Bill_English_Template.docx")
        docx_output = os.path.join(self.output_dir, f"Seizure_Bill_{case_id}.docx")
        if os.path.exists(docx_template):
            doc = docx.Document(docx_template)
            replacements = {
                "{{SEIZURE_RECEIPT_NO}}": receipt_no,
                "To,\nM/s. ________________________________________________________________________________": f"To,\nM/s. {firm_name}",
                "Business / Establishment: ____________________________________________________________________": f"Business / Establishment: {firm_name}, {firm_address}",
            }
            self._replace_text_in_doc(doc, replacements)
            doc.save(docx_output)

        # 2. PDF with ReportLab
        pdf_output = os.path.join(self.output_dir, f"Seizure_Bill_{case_id}.pdf")
        doc_pdf = SimpleDocTemplate(
            pdf_output,
            pagesize=A4,
            leftMargin=30,
            rightMargin=30,
            topMargin=26,
            bottomMargin=40
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle('HeaderTitle', fontName='Helvetica-Bold', fontSize=10.5, leading=13, alignment=1)
        sub_style = ParagraphStyle('HeaderSub', fontName='Helvetica-Bold', fontSize=9.5, leading=12, alignment=1)
        body_style = ParagraphStyle('BodyTextNorm', fontName='Times-Roman', fontSize=10, leading=14, alignment=4)
        small_style = ParagraphStyle('SmallText', fontName='Helvetica', fontSize=8.5, leading=11)

        story = []
        if os.path.exists(self.emblem_path):
            story.append(RLImage(self.emblem_path, width=65, height=68))
        story.append(Spacer(1, 4))

        story.append(Paragraph("GOVERNMENT OF MAHARASHTRA", title_style))
        story.append(Paragraph("FOOD, CIVIL SUPPLIES AND CONSUMER PROTECTION DEPARTMENT", sub_style))
        story.append(Paragraph("LEGAL METROLOGY ORGANISATION", title_style))
        story.append(Spacer(1, 3))
        story.append(Paragraph("<u>SEIZURE BILL / DETENTION MEMO</u>", title_style))
        story.append(Paragraph("<u>[Under Section 15 of The Legal Metrology Act, 2009]</u>", sub_style))
        story.append(Spacer(1, 8))

        ref_table = [
            [Paragraph(f"<b>Receipt No:</b> {receipt_no}", small_style), Paragraph(f"<b>Date:</b> {date_str}", small_style)]
        ]
        story.append(Table(ref_table, colWidths=[330, 205]))
        story.append(Spacer(1, 8))

        story.append(Paragraph(f"<b>To,</b><br/><b>M/s. {firm_name}</b><br/>{firm_address}", body_style))
        story.append(Spacer(1, 8))

        p_desc = (
            f"In exercise of the powers conferred upon me under Section 15 of the Legal Metrology Act, 2009, I have seized and "
            f"detained the following pre-packaged commodities / weights / measures from your premises on <b>{date_str}</b> "
            f"for reasons recorded hereunder:"
        )
        story.append(Paragraph(p_desc, body_style))
        story.append(Spacer(1, 8))

        table_data = [
            ["Item No.", "Details of Commodity / Package Seized", "Quantity", "Reasons for Seizure & Detention"],
            ["1.", commodity, qty, reason],
        ]
        t_items = Table(table_data, colWidths=[35, 220, 80, 200])
        t_items.setStyle(TableStyle([
            ('GRID', (0,0), (-1,-1), 0.5, colors.grey),
            ('BACKGROUND', (0,0), (-1,0), colors.whitesmoke),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 8.5),
            ('ALIGN', (0,0), (0,-1), 'CENTER'),
            ('ALIGN', (2,0), (2,-1), 'CENTER'),
            ('TOPPADDING', (0,0), (-1,-1), 5),
            ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ]))
        story.append(t_items)
        story.append(Spacer(1, 12))

        ack_text = (
            "<b>Receipt Acknowledged:</b><br/>"
            "The above particulars are correct and the seized articles have been sealed/tagged in my presence.<br/><br/>"
            "<i>(Signature of Trader / Representative)</i>"
        )
        story.append(Paragraph(ack_text, small_style))
        story.append(Spacer(1, 25))

        story.append(Paragraph(f"<b>{officer_name}</b><br/>Inspector of Legal Metrology", ParagraphStyle('LMO', fontName='Helvetica-Bold', fontSize=9, alignment=2)))

        def page_decorator(canv, doc):
            self._draw_official_frame(canv, doc, total_pages=1, is_signed=is_signed, signer_name=officer_name, sign_date=stamp_str, signature_img=signature_img)

        doc_pdf.build(story, onFirstPage=page_decorator, onLaterPages=page_decorator)

        return {
            "docx": docx_output,
            "pdf": pdf_output,
            "filename_docx": os.path.basename(docx_output),
            "filename_pdf": os.path.basename(pdf_output)
        }

    # =========================================================================
    # 4. SPOT PANCHANAMA (PDF & DOCX)
    # =========================================================================
    def generate_panchanama(self, data: Dict[str, Any], is_signed: bool = False, signer_name: str = "", signature_img: Optional[str] = None) -> Dict[str, str]:
        """
        Generates Spot Panchanama Record (CrPC Section 100 / LM Act Section 15(4)).
        Returns paths to both .docx and .pdf files.
        """
        case_id = data.get("case_id", "2026-PAN-01")
        panch_no = f"PAN-MH-{case_id}"
        now_local = datetime.now(IST)
        date_str = data.get("date", now_local.strftime("%d/%m/%Y"))
        time_str = data.get("time", now_local.strftime("%I:%M %p"))
        stamp_str = data.get("timestamp", now_local.strftime("%Y.%m.%d %H:%M:%S +05:30"))
        firm_name = data.get("firm_name", "M/s Gupta Retail LLP")
        firm_address = data.get("firm_address", "Pune, Maharashtra")
        officer_name = signer_name or data.get("ordering_officer_name", "LEGAL METROLOGY OFFICER")
        commodity = data.get("product_name", "Pre-packaged Atta 5kg")
        batch = data.get("batch_number", "BATCH-88A / 08-2026")
        offence = data.get("violation_summary", "Missing Mandatory Unit Sale Price & Inaccurate Net Quantity")
        seized_count = str(data.get("seized_count", "6"))
        witness1 = data.get("witness1", "Shri Amit Patil (Witness 1)")
        witness2 = data.get("witness2", "Shri Suresh Kadam (Witness 2)")

        # 1. DOCX
        docx_template = os.path.join(self.template_dir, "Panchanama_Template.docx")
        docx_output = os.path.join(self.output_dir, f"Panchanama_{case_id}.docx")
        if os.path.exists(docx_template):
            doc = docx.Document(docx_template)
            replacements = {
                "Name of the Establishment/Trader: ________________________________________________________": f"Name of the Establishment/Trader: {firm_name}",
                "Address: ____________________________________________________________________________________": f"Address: {firm_address}",
                "1. Description of Commodity: ______________________________________________________________": f"1. Description of Commodity: {commodity}",
                "2. Batch No. / Manufacturing Date: _________________________________________________________": f"2. Batch No. / Manufacturing Date: {batch}",
                "3. Nature of Offence: _______________________________________________________________________": f"3. Nature of Offence: {offence}",
                "The Legal Metrology Officer has seized ______ number of packages/samples": f"The Legal Metrology Officer has seized {seized_count} number of packages/samples",
            }
            self._replace_text_in_doc(doc, replacements)
            doc.save(docx_output)

        # 2. PDF with ReportLab
        pdf_output = os.path.join(self.output_dir, f"Panchanama_{case_id}.pdf")
        doc_pdf = SimpleDocTemplate(
            pdf_output,
            pagesize=A4,
            leftMargin=30,
            rightMargin=30,
            topMargin=26,
            bottomMargin=40
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle('HeaderTitle', fontName='Helvetica-Bold', fontSize=10.5, leading=13, alignment=1)
        sub_style = ParagraphStyle('HeaderSub', fontName='Helvetica-Bold', fontSize=9.5, leading=12, alignment=1)
        body_style = ParagraphStyle('BodyTextNorm', fontName='Times-Roman', fontSize=10, leading=14, alignment=4)
        small_style = ParagraphStyle('SmallText', fontName='Helvetica', fontSize=8.5, leading=11)

        story = []
        if os.path.exists(self.emblem_path):
            story.append(RLImage(self.emblem_path, width=65, height=68))
        story.append(Spacer(1, 4))

        story.append(Paragraph("GOVERNMENT OF MAHARASHTRA", title_style))
        story.append(Paragraph("LEGAL METROLOGY ORGANISATION", title_style))
        story.append(Spacer(1, 3))
        story.append(Paragraph("<u>SPOT PANCHANAMA</u>", title_style))
        story.append(Paragraph("<u>(Under Section 15(4) of Legal Metrology Act, 2009 & Section 100 Cr.P.C.)</u>", sub_style))
        story.append(Spacer(1, 8))

        ref_table = [
            [Paragraph(f"<b>Panchanama No:</b> {panch_no}", small_style), Paragraph(f"<b>Date:</b> {date_str}", small_style)]
        ]
        story.append(Table(ref_table, colWidths=[330, 205]))
        story.append(Spacer(1, 8))

        preamble = (
            f"We, the undersigned two independent witnesses (Panchas), were called by the Legal Metrology Officer today "
            f"at <b>{date_str}</b> to witness the search and inspection conducted at the following establishment:"
        )
        story.append(Paragraph(preamble, body_style))
        story.append(Spacer(1, 6))

        est_info = [
            ["Establishment / Trader:", firm_name],
            ["Address:", firm_address],
            ["Commodity Inspected:", commodity],
            ["Batch No. / Mfd Date:", batch],
            ["Nature of Violation:", offence],
            ["Seized Packages Count:", f"{seized_count} packages/samples detained as evidence"],
        ]
        t_est = Table(est_info, colWidths=[160, 375])
        t_est.setStyle(TableStyle([
            ('GRID', (0,0), (-1,-1), 0.5, colors.grey),
            ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 8.5),
            ('TOPPADDING', (0,0), (-1,-1), 4),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        story.append(t_est)
        story.append(Spacer(1, 10))

        closing = (
            "The contents of this Panchanama were read over and explained to us in a language understood by us, and we "
            "confirm that the search, sampling, and seizure were performed strictly in our presence without any threat, force, or coercion."
        )
        story.append(Paragraph(closing, body_style))
        story.append(Spacer(1, 15))

        # Panch signatures table
        panch_sig = [
            [Paragraph(f"1. ____________________________<br/><b>Panch 1:</b> {witness1}", small_style),
             Paragraph(f"2. ____________________________<br/><b>Panch 2:</b> {witness2}", small_style)],
        ]
        story.append(Table(panch_sig, colWidths=[270, 265]))
        story.append(Spacer(1, 20))

        story.append(Paragraph(f"<b>{officer_name}</b><br/>Inspector of Legal Metrology", ParagraphStyle('LMO', fontName='Helvetica-Bold', fontSize=9, alignment=2)))

        def page_decorator(canv, doc):
            self._draw_official_frame(canv, doc, total_pages=1, is_signed=is_signed, signer_name=officer_name, sign_date=stamp_str, signature_img=signature_img)

        doc_pdf.build(story, onFirstPage=page_decorator, onLaterPages=page_decorator)

        return {
            "docx": docx_output,
            "pdf": pdf_output,
            "filename_docx": os.path.basename(docx_output),
            "filename_pdf": os.path.basename(pdf_output)
        }
