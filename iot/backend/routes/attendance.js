const express = require("express");
const { body, validationResult } = require("express-validator");
const {
  getTodaySchedule,
  getTodayAttendance,
  checkScheduleTime,
  createAttendance,
  getAttendanceStats,
  createLogActivity,
} = require("../services/attendanceService");
const { checkRegisterStatus,updateRFID } = require("../services/rfid");
const { verifyDevice } = require("../middleware/auth");
const { findUserByRFID } = require("../services/userService");
const { addUserPoint } = require("../services/gamifikasiService");
const router = express.Router();

/**
 * POST /api/attendance/scan
 * Record attendance from RFID scan
 */
router.post(
  "/scan",
  verifyDevice,
  [
    body("rfidUid").notEmpty().withMessage("RFID UID is required"),
    body("rfidUid").isString().withMessage("RFID UID must be a string"),
  ],
  async (req, res, next) => {

    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          error: "Validation error",
          details: errors.array(),
        });
      }

      const { rfidUid } = req.body;
      const deviceId = req.device.id;

      console.log(`RFID scan received: ${rfidUid} from device: ${deviceId}`);
      const result = await checkRegisterStatus();
      if (result && result.isActive) {
        const response = await updateRFID(result.id,rfidUid,result.userId);
        res.status(200).json({
          success: true,
          message: response ?? "RFID berhasil didaftarkan",
        });
        return;
      }
      const schedule = await getTodaySchedule();
      
      if (!schedule) {
        return res.status(403).json({
          success: false,
          message: "Tidak ada jadwal untuk hari ini",
        });
      }
      if (schedule.status === "too_early") {
        return res.status(403).json({
          success: false,
          message: schedule.message,
        });
      }
      if (schedule.status === "too_late") {
        return res.status(403).json({
          success: false,
          message: schedule.message,
        });
      }
      if (schedule.status === "unknown") {
        return res.status(403).json({
          success: false,
          message: schedule.message,
        });
      }
      if (!schedule.isAktif) {
        return res.status(403).json({
          success: false,
          message: schedule.message,
        });
      }

      // mencari user berdasarkan rfid
      const user = await findUserByRFID(rfidUid);
      if (!user) {
        return res.status(403).json({
          success: false,
          message: "RFID Belum di daftarkan",
        });
      }
      // mendapatkan data presensi hari ini
      const todayAttendance = await getTodayAttendance(schedule.id, user.id);
      if (!todayAttendance) {
        return res.status(403).json({
          success: false,
          message: "Tidak ada presensi untukmu",
        });
      }
      // mengecek hadir atau tidak
      if (todayAttendance.status === "hadir") {
        return res.status(403).json({
          success: true,
          message: "Presensi sudah dicatat",
        });
      }
      
      // Get poin from schedule, default to 1 if not set
      const poin = schedule.poin || 1;
      
      // Add tanggal to attendance data
      const attendanceData = {
        ...todayAttendance,
        tanggal: schedule.tanggal.toDate(),
      };
      
      await createAttendance(attendanceData, poin);
      
      const attendancePoin = poin;
      // await addUserPoint(user, attendancePoin);
      await createLogActivity({
        description: `${user.nama} - ${user.id}: Hadir, point added ${attendancePoin}`,
        title: "Absensi RFID",
        type: "rfid_attendance",
        recordedBy: user.id,
      });
      return res.status(200).json({
        success: true,
        message: "Presensi sudah dicatat",
      });
    } catch (error) {
      next(error);
    }
  }
);
router.get("/test", async (req, res, next) => {
  
});
module.exports = router;