module.exports = {
  install (db) {
    db.folder = {
      getFoldersForUser (id) {
        return db.query(id)
      }
    }
  }
}
