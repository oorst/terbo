module.exports = function (pool) {
  return {
    getUserProfileByEmail (email) {
      var query = `SELECT get_user_profile_by_email('${email}') AS user`

      return new Promise((resolve, reject) => {
        pool.query(query, (err, result) => {
          if (err) reject(err)
          else resolve(result.rows[0].user)
        })
      })
    },

    newPasswordReset (email) {
      var query = `SELECT access_control.create_reset_token('${email}') AS reset`

      return new Promise((resolve, reject) => {
        pool.query(query, (err, result) => {
          if (err) {
            reject(err)
          } else {
            result = result.rows[0].reset
            if (!result) reject(null)
            else resolve(result)
          }
        })
      })
    },

    /**
    Checks that the passed key belongs to a valid reset token.
    @function checkResetToken
    @param {string} key
    @return {number} 0 on success, 1 if key not found, 2 if key has expired.
    */
    checkResetToken (key) {
      // Perform a check to see if the key looks like a uuid
      if (!/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.test(key)) {
        return Promise.resolve(1)
      }

      var query = `SELECT access_control.check_reset_token($$${key}$$) AS check`

      return new Promise((resolve, reject) => {
        pool.query(query, (err, result) => {
          if (err) reject(err)
          else resolve(result.rows[0].check)
        })
      })
    },

    /**
    Gets a valid reset token
    @function getResetToken
    @param {string} key
    @return {Promise} Resolves to reset token on success or an error object on
    failure.
    */
    getResetToken (key) {
      return new Promise((resolve, reject) => {
        pool.query(`SELECT access_control.get_reset_token($$${key}$$) AS token`, (err, result) => {
          if (err) reject(err)
          else resolve(result.rows[0].token)
        })
      })
    },

    /**
    Update a user's password by passing a valid key and a new password.
    @function useResetToken
    @param {string} key
    @param {string} password
    @return {Promise} Promise resolves with 0 on success. Promise rejects with
    1 if key not found, with 2 if key has expired.
    */
    useResetToken (key, password) {
      // Perform a check to see if the key looks like a uuid
      if (!/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.test(key)) {
        return Promise.reject(1)
      }

      var query = `SELECT access_control.update_password($$${key}$$, $_pass$${password}$_pass$) AS reset`

      return new Promise((resolve, reject) => {
        pool.query(query, (err, result) => {
          if (err) reject(err)
          else resolve(result.rows[0].reset)
        })
      })
    }
  }
}
