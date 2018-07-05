export default function (pool) {
  return {
    getCustomer (queryObject) {
      var query, param

      if (param = queryObject.customer_id) {
        query = `SELECT get_customer_by_id('${param}') AS customer`
      }

      return new Promise((resolve, reject) => {
        pool.query(query, (err, result) => {
          if (err) {
            reject(err);
          } else {
            resolve(result.rows[0].customer)
          }
        })
      })
    },

    getPerson (queryObject) {
      var query

      if (queryObject.email) {
        query = `SELECT get_person_by_email('${queryObject.email}') AS person`
      } else if (queryObject.id) {
        query = `SELECT get_person_by_id('${queryObject.id}') AS person`
      }

      return new Promise((resolve, reject) => {
        pool.query(query, (err, result) => {
          if (err) {
            reject(err);
          } else {
            resolve(result.rows[0].person)
          }
        })
      })
    }
  }
}

module.exports = function (pool) {
  return {



  }
}
