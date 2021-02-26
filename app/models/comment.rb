class Comment < ApplicationRecord
  belongs_to :commenter, class_name: "User"
  belongs_to :commentable, polymorphic: true
end
