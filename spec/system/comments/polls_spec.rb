require "rails_helper"

describe "Commenting polls" do
  let(:user) { create(:user) }
  let(:poll) { create(:poll, author: create(:user)) }

  scenario "Reply" do
    citizen = create(:user, username: "Ana")
    manuela = create(:user, username: "Manuela")
    comment = create(:comment, commentable: poll, user: citizen)

    login_as(manuela)
    visit poll_path(poll)

    click_link "Reply"

    within "#js-comment-form-comment_#{comment.id}" do
      fill_in "Leave your comment", with: "It will be done next week."
      click_button "Publish reply"
    end

    within "#comment_#{comment.id}" do
      expect(page).to have_content "It will be done next week."
    end

    expect(page).not_to have_css "#js-comment-form-comment_#{comment.id}"
  end

  scenario "Reply update parent comment responses count" do
    comment = create(:comment, commentable: poll)

    login_as(create(:user))
    visit poll_path(poll)

    within ".comment", text: comment.body do
      click_link "Reply"
      fill_in "Leave your comment", with: "It will be done next week."
      click_button "Publish reply"

      expect(page).to have_content("1 response (collapse)")
    end
  end

  scenario "Reply show parent comments responses when hidden" do
    comment = create(:comment, commentable: poll)
    create(:comment, commentable: poll, parent: comment)

    login_as(create(:user))
    visit poll_path(poll)

    within ".comment", text: comment.body do
      click_link text: "1 response (collapse)"
      click_link "Reply"
      fill_in "Leave your comment", with: "It will be done next week."
      click_button "Publish reply"

      expect(page).to have_content("It will be done next week.")
    end
  end

  scenario "Errors on reply" do
    comment = create(:comment, commentable: poll, user: user)

    login_as(user)
    visit poll_path(poll)

    click_link "Reply"

    within "#js-comment-form-comment_#{comment.id}" do
      click_button "Publish reply"
      expect(page).to have_content "Can't be blank"
    end
  end

  scenario "N replies" do
    parent = create(:comment, commentable: poll)

    7.times do
      create(:comment, commentable: poll, parent: parent)
      parent = parent.children.first
    end

    visit poll_path(poll)
    expect(page).to have_css(".comment.comment.comment.comment.comment.comment.comment.comment")
  end

  scenario "Erasing a comment's author" do
    poll = create(:poll)
    comment = create(:comment, commentable: poll, body: "this should be visible")
    comment.user.erase

    visit poll_path(poll)
    within "#comment_#{comment.id}" do
      expect(page).to have_content("User deleted")
      expect(page).to have_content("this should be visible")
    end
  end

  describe "Moderators" do
    scenario "can create comment as a moderator" do
      moderator = create(:moderator)

      login_as(moderator.user)
      visit poll_path(poll)

      fill_in "Leave your comment", with: "I am moderating!"
      check "comment-as-moderator-poll_#{poll.id}"
      click_button "Publish comment"

      within "#comments" do
        expect(page).to have_content "I am moderating!"
        expect(page).to have_content "Moderator ##{moderator.id}"
        expect(page).to have_css "div.is-moderator"
        expect(page).to have_css "img.moderator-avatar"
      end
    end

    scenario "can create reply as a moderator" do
      citizen = create(:user, username: "Ana")
      manuela = create(:user, username: "Manuela")
      moderator = create(:moderator, user: manuela)
      comment = create(:comment, commentable: poll, user: citizen)

      login_as(manuela)
      visit poll_path(poll)

      click_link "Reply"

      within "#js-comment-form-comment_#{comment.id}" do
        fill_in "Leave your comment", with: "I am moderating!"
        check "comment-as-moderator-comment_#{comment.id}"
        click_button "Publish reply"
      end

      within "#comment_#{comment.id}" do
        expect(page).to have_content "I am moderating!"
        expect(page).to have_content "Moderator ##{moderator.id}"
        expect(page).to have_css "div.is-moderator"
        expect(page).to have_css "img.moderator-avatar"
      end

      expect(page).not_to have_css "#js-comment-form-comment_#{comment.id}"
    end

    scenario "can not comment as an administrator" do
      moderator = create(:moderator)

      login_as(moderator.user)
      visit poll_path(poll)

      expect(page).not_to have_content "Comment as administrator"
    end
  end

  describe "Administrators" do
    scenario "can create comment as an administrator" do
      admin = create(:administrator)

      login_as(admin.user)
      visit poll_path(poll)

      fill_in "Leave your comment", with: "I am your Admin!"
      check "comment-as-administrator-poll_#{poll.id}"
      click_button "Publish comment"

      within "#comments" do
        expect(page).to have_content "I am your Admin!"
        expect(page).to have_content "Administrator ##{admin.id}"
        expect(page).to have_css "div.is-admin"
        expect(page).to have_css "img.admin-avatar"
      end
    end

    scenario "can create reply as an administrator" do
      citizen = create(:user, username: "Ana")
      manuela = create(:user, username: "Manuela")
      admin   = create(:administrator, user: manuela)
      comment = create(:comment, commentable: poll, user: citizen)

      login_as(manuela)
      visit poll_path(poll)

      click_link "Reply"

      within "#js-comment-form-comment_#{comment.id}" do
        fill_in "Leave your comment", with: "Top of the world!"
        check "comment-as-administrator-comment_#{comment.id}"
        click_button "Publish reply"
      end

      within "#comment_#{comment.id}" do
        expect(page).to have_content "Top of the world!"
        expect(page).to have_content "Administrator ##{admin.id}"
        expect(page).to have_css "div.is-admin"
        expect(page).to have_css "img.admin-avatar"
      end

      expect(page).not_to have_css "#js-comment-form-comment_#{comment.id}"
    end

    scenario "can not comment as a moderator", :admin do
      visit poll_path(poll)

      expect(page).not_to have_content "Comment as moderator"
    end
  end

  describe "Voting comments" do
    let(:verified)   { create(:user, verified_at: Time.current) }
    let(:unverified) { create(:user) }
    let(:poll)       { create(:poll) }
    let!(:comment)   { create(:comment, commentable: poll) }

    before do
      login_as(verified)
    end

    scenario "Show" do
      create(:vote, voter: verified, votable: comment, vote_flag: true)
      create(:vote, voter: unverified, votable: comment, vote_flag: false)

      visit poll_path(poll)

      within("#comment_#{comment.id}_votes") do
        within(".in-favor") do
          expect(page).to have_content "1"
        end

        within(".against") do
          expect(page).to have_content "1"
        end

        expect(page).to have_content "2 votes"
      end
    end

    scenario "Create" do
      visit poll_path(poll)

      within("#comment_#{comment.id}_votes") do
        click_button "I agree"

        within(".in-favor") do
          expect(page).to have_content "1"
        end

        within(".against") do
          expect(page).to have_content "0"
        end

        expect(page).to have_content "1 vote"
      end
    end

    scenario "Update" do
      visit poll_path(poll)

      within("#comment_#{comment.id}_votes") do
        click_button "I agree"

        within(".in-favor") do
          expect(page).to have_content "1"
        end

        click_button "I disagree"

        within(".in-favor") do
          expect(page).to have_content "0"
        end

        within(".against") do
          expect(page).to have_content "1"
        end

        expect(page).to have_content "1 vote"
      end
    end

    scenario "Allow undoing votes" do
      visit poll_path(poll)

      within("#comment_#{comment.id}_votes") do
        click_button "I agree"

        within(".in-favor") do
          expect(page).to have_content "1"
        end

        click_button "I agree"

        within(".in-favor") do
          expect(page).to have_content "0"
        end

        within(".against") do
          expect(page).to have_content "0"
        end

        expect(page).to have_content "No votes"
      end
    end
  end
end
