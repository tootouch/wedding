const SPREADSHEET_ID = "";

const GUESTBOOK_SHEET_NAME = "GUESTBOOK";
const GUESTBOOK_HEADERS = [
  "id",
  "createdAt",
  "target",
  "message",
  "name",
  "relation",
  "passwordHash",
  "source",
  "deletedAt",
];

function doPost(e) {
  const payload = JSON.parse((e && e.postData && e.postData.contents) || "{}");

  return output_({ ok: true, item: createGuestbook_(payload) });
}

function doGet() {
  return ContentService
    .createTextOutput("Wedding invitation endpoint is ready.")
    .setMimeType(ContentService.MimeType.TEXT);
}

function setup() {
  getSheet_(GUESTBOOK_SHEET_NAME, GUESTBOOK_HEADERS);
}

function createGuestbook_(payload) {
  const sheet = getSheet_(GUESTBOOK_SHEET_NAME, GUESTBOOK_HEADERS);
  const item = {
    id: payload.id || Utilities.getUuid(),
    createdAt: payload.savedAt || payload.createdAt || new Date().toISOString(),
    target: payload.target || "",
    message: payload.message || "",
    name: payload.name || "",
    relation: payload.relation || "",
    source: payload.source || "",
  };

  sheet.appendRow([
    item.id,
    item.createdAt,
    item.target,
    item.message,
    item.name,
    item.relation,
    "",
    item.source,
    "",
  ]);

  return item;
}

function getSheet_(name, headers) {
  const spreadsheet = getSpreadsheet_();
  let sheet = spreadsheet.getSheetByName(name);
  if (!sheet) {
    sheet = spreadsheet.insertSheet(name);
  }

  if (sheet.getLastRow() === 0) {
    sheet.appendRow(headers);
    sheet.setFrozenRows(1);
  }

  return sheet;
}

function getSpreadsheet_() {
  const spreadsheet = SPREADSHEET_ID
    ? SpreadsheetApp.openById(SPREADSHEET_ID)
    : SpreadsheetApp.getActiveSpreadsheet();

  if (!spreadsheet) {
    throw new Error("Create this script from Google Sheets, or set SPREADSHEET_ID.");
  }

  return spreadsheet;
}

function output_(payload, callback) {
  const safeCallback = sanitizeCallback_(callback);
  const json = JSON.stringify(payload);

  if (safeCallback) {
    return ContentService
      .createTextOutput(`${safeCallback}(${json});`)
      .setMimeType(ContentService.MimeType.JAVASCRIPT);
  }

  return ContentService
    .createTextOutput(json)
    .setMimeType(ContentService.MimeType.JSON);
}

function sanitizeCallback_(callback) {
  if (!callback) {
    return "";
  }

  return /^[A-Za-z_$][0-9A-Za-z_$]*(\.[A-Za-z_$][0-9A-Za-z_$]*)*$/.test(callback)
    ? callback
    : "";
}
