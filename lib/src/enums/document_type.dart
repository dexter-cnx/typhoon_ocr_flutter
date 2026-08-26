/// Built-in document categories supported by the default OCR definitions.
enum DocumentType {
  /// Thai national identity card.
  thaiIdCard,

  /// Purchase receipt.
  receipt,

  /// Bank transfer or payment slip.
  bankSlip,

  /// Passport identity page.
  passport,

  /// General document without a specialized schema.
  general,
}
