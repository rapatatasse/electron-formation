class UserSession
  def self.method_missing(*)
    raise NameError, 'UserSession has been removed. Use QuizParticipant/QuizSession instead.'
  end
end
