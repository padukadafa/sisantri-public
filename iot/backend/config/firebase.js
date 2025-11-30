const base64 = require('base-64');
process.env.FIRESTORE_ENABLE_TELEMETRY = "false";
process.env.GOOGLE_CLOUD_ENABLE_TELEMETRY = "false";

const admin = require("firebase-admin");
require("dotenv").config();

const privateKey = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDIt41P4BnAbWIJ\nYOZCIbYBUEmE9VJWaPggh0ZLhusk4Tjr2Z1HEkN09R84WATa5ekdvxRaGRZ5jDY2\ndUh6E8l07iFkpxTHZP9l6jR8HogG5uM3fXsMRJoZfgmRW9nsqU7cT/ENcx8BsK/K\nApgKmsP4d/ojDiSfc92XOG0wmctu/55w4Y0BGFMHx14LxwZD8whX5U+OqQvow7Au\nb6c3Gpnev26mJPSO/oMhbQqQOFC2t54DwVGBY9f1NcWdZy5XCHBUHBuVAr9dQZBq\nYb0E9flBqiM33NIK3mVht8Pu3ZDQHMg+riMaoS0cYdGiCmJNNOus2W5J3NqZWmlt\nrtcr61cTAgMBAAECggEAKxSumYbVsCYqJS4treMTcBu98/I9znswSrcOQPa/8MYA\nlCq8pb0HSoq0PUEzJZK0YuSY5y+8UbFlD3JD8KPfmR/lffeYr6V/Ze4LftqEwsp6\n2XWu2/a7hp41SoRG9ZNvcD0eVY8wiAnW6Up+PMR0LJf/0ddex/S0CpmbYhOYhQWq\nOucfivPe50lZ9EWoqa4jM5/rumcnQjAgrKe7zHY8qxY0lk86/jDHpIPh4TnklupX\nVf60FvjRKPMg9Gj328BVpnwiIXANjTyBXqcEuvIAFkTyx5QKzZUNFz95FNlPeyuw\nof04e80fcJ3Zc1qxLnKS2MDl9hZkyhIM1SXaHauuSQKBgQDixLg9qOfAh3wSN8bw\nlm7CvFh34oR0cvtGiClkWmnJPWchlDnOgkZtJYODm9UnpeZInuFH4BDimr4WbJG3\nHE5EKJtfkJJgg8dsez1+Yvs6N4HP0dzjJnUqvbjunRX1AS+6J7giWDxNiY5feYqU\nuwGS/fkYkSaAIsNhkYYzRzq9+wKBgQDilyTVexahv9BkZReJHmIRizkjOtrKaW15\nNGmT5AiPc+mqH2FWmQDQLOUknzyzGf3MhTSXAgu3CMQIMY3bGAkyD4jXEbrsizN2\nKiedGMC3oK7al1mtCTHF0rrhXIvrCgZmrjMUiE8jlsUaixBZnKbCxRDb+lBwkSCe\ncjxTt033yQKBgQCfgoaigLP73pFscyWRyA9DFZ8ZPRG0o8iSdWbAO0TcFD/+A7ih\nxUtqrQ+UPMIz8GNKw89tcnQOIZECTv40kkmPcgzQrO35y9g0O4Am7dMPwUmjeFhq\nw3t5RBjYZ1CxlVMQG65PIkfQtqiaCfFr6xsRXWqhWEB/s3RBpk6CtWDhjwKBgQCs\n2RFPDFNKVfEY9IjMn3G94k9W0YmfCGdrIxE6sKPbElf333I4RgT5yJWPpyz9juEt\nR5vDadsX58bqXSrSK/avymvfa/YEhXdfN276hqxUJ23a78OHnNDsEAFg8mEFjaMu\nZsouaoC8LEH1KonxYe9P+lYPCFaeWAbi90+PqPAACQKBgDdUrXIJ3zTtmdgS1Rz4\nZQ+NNwnY70m62xdzZOVDXxceiOBM67MwJNMhPMNZGvpVqj/ljNIKQ4L9uzKn/HI1\nHrJOUZAdhBVhHZcDe2vi7cyRzi/UsJa8c/7sFl6dm/66aNoyXEPT6W7CH1K3IRvT\n7q3gUhc73+W5uv4jIXD4CIZ5\n-----END PRIVATE KEY-----\n"

const serviceAccount = {
  type: "service_account",
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key: privateKey,
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
};

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
db.settings({ preferRest: true });

const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

module.exports = { admin, db, FieldValue, Timestamp };
