class User
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :id, :string
  attribute :email, :string
  attribute :name, :string
  attribute :image, :string
  attribute :token, :string
  attribute :refresh_token, :string
  attribute :token_expires_at, :integer
  
  def self.from_omniauth(auth)
    user = User.new(
      id: auth.uid,
      email: auth.info.email,
      name: auth.info.name,
      image: auth.info.image,
      token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      token_expires_at: auth.credentials.expires_at
    )
    
    # Store in session
    user
  end
  
  def token_expired?
    token_expires_at < Time.now.to_i
  end
  
  def to_session
    {
      'id' => id,
      'email' => email,
      'name' => name,
      'image' => image,
      'token' => token,
      'refresh_token' => refresh_token,
      'token_expires_at' => token_expires_at
    }
  end
  
  def self.from_session(session_data)
    return nil unless session_data
    
    User.new(
      id: session_data['id'],
      email: session_data['email'],
      name: session_data['name'],
      image: session_data['image'],
      token: session_data['token'],
      refresh_token: session_data['refresh_token'],
      token_expires_at: session_data['token_expires_at']
    )
  end
end