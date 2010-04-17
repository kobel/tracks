Given /^I have a project "([^\"]*)" with (.*) todos$/ do |project_name, num_todos|
  context = @current_user.contexts.create!(:name => "Context A")
  project = @current_user.projects.create!(:name => project_name)
  1.upto num_todos.to_i do |i|
    @current_user.todos.create!(
      :project_id => project.id,
      :context_id => context.id,
      :description => "Todo #{i}")
  end
end

Given /^there exists a project "([^\"]*)" for user "([^\"]*)"$/ do |project_name, user_name|
  user = User.find_by_login(user_name)
  user.should_not be_nil
  user.projects.create!(:name => project_name)
end

When /^I visit the "([^\"]*)" project$/ do |project_name|
  @project = Project.find_by_name(project_name)
  @project.should_not be_nil
  visit project_path(@project)
end

When /^I edit the project description to "([^\"]*)"$/ do |new_description|
  click_link "link_edit_project_#{@project.id}"
  fill_in "project[description]", :with => new_description
  click_button "submit_project_#{@project.id}"
end

Then /^I should see the bold text "([^\"]*)" in the project description$/ do |bold|
  xpath="//div[@class='project_description']/p/strong"

  response.should have_xpath(xpath)
  bold_text = response.selenium.get_text("xpath=#{xpath}")
  
  bold_text.should =~ /#{bold}/
end

Then /^I should see the italic text "([^\"]*)" in the project description$/ do |italic|
  xpath="//div[@class='project_description']/p/em"

  response.should have_xpath(xpath)
  italic_text = response.selenium.get_text("xpath=#{xpath}")

  italic_text.should =~ /#{italic}/
end
