function getWIBDate(date = new Date()) {
  if (process.env.PRODUCTION === 'false') {
    return date;
  }
  const utc = date.getTime() + date.getTimezoneOffset() * 60000;
  const wib = new Date(utc + 7 * 3600000);
  wib.setDate(wib.getDate()-1);
  return wib;
}

/**
 * Get periode key for aggregate based on periode type
 * @param {string} periode - Periode type (daily, weekly, monthly, semester, yearly)
 * @param {Date} date - Date to generate key from
 * @returns {string} Periode key
 */
function getPeriodeKey(periode, date) {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();

  switch (periode) {
    case 'daily':
      return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    
    case 'weekly':
      // Get week number
      const startOfYear = new Date(year, 0, 1);
      const days = Math.floor((date - startOfYear) / (24 * 60 * 60 * 1000));
      const weekNumber = Math.ceil((days + startOfYear.getDay() + 1) / 7);
      return `${year}-W${String(weekNumber).padStart(2, '0')}`;
    
    case 'monthly':
      return `${year}-${String(month).padStart(2, '0')}`;
    
    case 'semester':
      // Semester 1: Jan-Jun, Semester 2: Jul-Dec
      const semester = month <= 6 ? 1 : 2;
      return `${year}-S${semester}`;
    
    case 'yearly':
      return `${year}`;
    
    default:
      throw new Error(`Invalid periode type: ${periode}`);
  }
}

/**
 * Get all periode keys for a given date
 * @param {Date} date - Date to generate keys from
 * @returns {Object} Object with all periode keys
 */
function getAllPeriodeKeys(date) {
  return {
    daily: getPeriodeKey('daily', date),
    weekly: getPeriodeKey('weekly', date),
    monthly: getPeriodeKey('monthly', date),
    semester: getPeriodeKey('semester', date),
    yearly: getPeriodeKey('yearly', date)
  };
}

module.exports = {
  getWIBDate,
  getPeriodeKey,
  getAllPeriodeKeys
};
