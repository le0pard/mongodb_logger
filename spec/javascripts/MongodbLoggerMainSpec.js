describe("MongodbLoggerMain", function() {

  beforeEach(function() {
    MongodbLoggerMain.init();
  });
  
  describe("logInfoPadding", function() {
    it("should be 15", function() {
      expect(MongodbLoggerMain.logInfoPadding).toEqual(15);
    });
  });
  
});