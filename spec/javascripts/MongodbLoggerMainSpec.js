describe("MongodbLoggerMain", function() {

  beforeEach(function() {
    MongodbLoggerMain.init();
  });
  
  describe("log_info_padding", function() {
    it("should be 15", function() {
      expect(MongodbLoggerMain.log_info_padding).toEqual(15);
    });
  });
  
});