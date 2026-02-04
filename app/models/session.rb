class Session
  def self.method_missing(*)
    raise NameError, 'Session has been removed. Use QuizSession instead.'
  end
end
