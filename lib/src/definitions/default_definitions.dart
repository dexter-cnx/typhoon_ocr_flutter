import '../enums/document_type.dart';
import '../models/bank_slip.dart';
import '../models/general_doc.dart';
import '../models/passport.dart';
import '../models/receipt.dart';
import '../models/thai_id_card.dart';
import '../parsers/parser.dart';
import 'document_definition.dart';

const _thaiIdPrompt =
    'Extract this Thai national ID card. Return one JSON object only with keys: '
    'id_number, title_th, firstname_th, lastname_th, dob, address, issue_date, expiry_date. '
    'Preserve Thai text exactly as printed. Keep the 13-digit ID number as digits only. '
    'Do not add commentary.';

const _receiptPrompt =
    'Extract this receipt. Return one JSON object only with keys: '
    'merchant_name, branch, date, items, subtotal, vat, total, payment_method. '
    'items must be an array of objects with name, quantity, price. '
    'Return numeric monetary values as numbers when possible. Do not add commentary.';

const _bankSlipPrompt =
    'Extract this bank transfer slip. Return one JSON object only with keys: '
    'from_bank, to_bank, from_account, to_account, from_name, to_name, amount, fee, currency, '
    'datetime, reference_no, transaction_id. Preserve names and reference identifiers exactly. '
    'Return amount and fee as numbers when possible. Do not add commentary.';

const _passportPrompt =
    'Extract this passport. Return one JSON object only with keys: '
    'passport_no, type, country_code, surname, given_names, nationality, dob, place_of_birth, '
    'sex, issue_date, expiry_date, authority, mrz_line1, mrz_line2. '
    'Preserve MRZ characters exactly as printed, including < filler characters. '
    'Do not add commentary.';

const _generalPrompt =
    'Extract all visible document content as structured Markdown. Preserve headings, paragraphs, '
    'lists and tables. Use Markdown tables when possible and HTML only when a table cannot be '
    'represented faithfully in Markdown. Do not summarize or omit visible content.';

Map<Type, DocumentDefinition<dynamic>> createDefaultDocumentDefinitions() => {
      ThaiIdCard: DocumentDefinition<ThaiIdCard>(
        type: DocumentType.thaiIdCard,
        prompt: _thaiIdPrompt,
        mode: 'structure',
        decode: TyphoonParser.parse<ThaiIdCard>,
      ),
      Receipt: DocumentDefinition<Receipt>(
        type: DocumentType.receipt,
        prompt: _receiptPrompt,
        mode: 'default',
        decode: TyphoonParser.parse<Receipt>,
      ),
      BankSlip: DocumentDefinition<BankSlip>(
        type: DocumentType.bankSlip,
        prompt: _bankSlipPrompt,
        mode: 'default',
        decode: TyphoonParser.parse<BankSlip>,
      ),
      Passport: DocumentDefinition<Passport>(
        type: DocumentType.passport,
        prompt: _passportPrompt,
        mode: 'structure',
        decode: TyphoonParser.parse<Passport>,
      ),
      GeneralDocument: DocumentDefinition<GeneralDocument>(
        type: DocumentType.general,
        prompt: _generalPrompt,
        mode: 'default',
        decode: TyphoonParser.parse<GeneralDocument>,
      ),
    };

DocumentDefinition<dynamic>? defaultDefinitionForType(DocumentType type) {
  for (final definition in createDefaultDocumentDefinitions().values) {
    if (definition.type == type) return definition;
  }
  return null;
}
