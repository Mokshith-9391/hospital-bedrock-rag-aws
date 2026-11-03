"""OCR adapter.

Production implementation:
- Upload scanned PDFs/images to S3.
- Invoke Amazon Textract asynchronously for multi-page PDFs.
- Persist normalized text plus page/line metadata.
- Feed the normalized artifact into the Bedrock Knowledge Base data source.

This module intentionally keeps the adapter small so OCR can be tested independently.
"""
import boto3

textract = boto3.client("textract")

def start_pdf_analysis(bucket, key, feature_types=None):
    return textract.start_document_analysis(
        DocumentLocation={"S3Object": {"Bucket": bucket, "Name": key}},
        FeatureTypes=feature_types or ["TABLES", "FORMS"]
    )
