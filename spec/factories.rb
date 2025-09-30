FactoryBot.define do

  ALPHABET = "ABCD EFG HIJKLMN OPQR STU VWXYZ" unless defined? ALPHABET
  LOWERCASE = ALPHABET.downcase unless defined? LOWERCASE

  sequence :word do |n|
    one = LOWERCASE.shuffle[0..10]
    two = ALPHABET.shuffle[0..10]
    "#{one + two} #{n}".shuffle
  end

  sequence :email_address do |n|
    "#{LOWERCASE.shuffle.gsub( " ", "" )}" + "@fakehatecrimes.org"
  end

  factory :user do
    email { generate( :email_address ) }
    password { User::VALID_PASSWORD }
    password_confirmation { User::VALID_PASSWORD }
    secret_word { "cheese" }
  end

  factory :article do
    name { generate( :word ) }
  end

  factory :admin, :parent => :user do
    email { User::ADMIN }
  end

  factory :medium do
    url  { "http://fakehatecrimes.org/" }
    title { generate( :word ) + ' ' + generate( :word ) }
    body  { generate( :word ) }
    retrieval_date   { Date.new(2011, 1, 17) }
    publication_date { Date.new(2011, 1, 16) }
    article { create :article }
    user{ create :user }
  end

  factory :fake do
    user
    media_type
    city {"Ashland"}
    state {"OR"}
    media { [ FactoryBot.build( :medium ) ] }
  end

  factory :invalid_fake, :parent => :fake do
    user {nil}
    media_type {nil}
    media {[ ]}
  end

end
