Given /^I have no todos$/ do
  Todo.delete_all
end

Given /^I have ([0-9]+) todos$/ do |count|
  context = @current_user.contexts.create!(:name => "context A")
  count.to_i.downto 1 do |i|
    @current_user.todos.create!(:context_id => context.id, :description => "todo #{i}")
  end
end

Given /^I have ([0-9]+) deferred todos$/ do |count|
  context = @current_user.contexts.create!(:name => "context B")
  count.to_i.downto 1 do |i|
    @current_user.todos.create!(:context_id => context.id, :description => "todo #{i}", :show_from => @current_user.time + 1.week)
  end
end

Given /^I have ([0-9]+) completed todos$/ do |count|
  context = @current_user.contexts.create!(:name => "context C")
  count.to_i.downto 1 do |i|
    todo = @current_user.todos.create!(:context_id => context.id, :description => "todo #{i}")
    todo.complete!
  end
end

Given /^"(.*)" depends on "(.*)"$/ do |successor_name, predecessor_name|
  successor = Todo.find_by_description(successor_name)
  predecessor = Todo.find_by_description(predecessor_name)
  
  successor.add_predecessor(predecessor)
  successor.state = "pending"
  successor.save!
end

When /^I drag "(.*)" to "(.*)"$/ do |dragged, target|
  drag_id = Todo.find_by_description(dragged).id
  drop_id = Todo.find_by_description(target).id
  drag_name = "xpath=//div[@id='line_todo_#{drag_id}']//img[@class='grip']"
  # xpath does not seem to work here... reverting to css
  # xpath=//div[@id='line_todo_#{drop_id}']//img[@class='successor_target']
  drop_name = "css=div#line_todo_#{drop_id} img.successor_target"

  # HACK: the target img is hidden until drag starts. We need to show the img or the
  # xpath will not find it
  js="$('div#line_todo_#{drop_id} img.successor_target').show();"
  selenium.get_eval "(function() {with(this) {#{js}}}).call(selenium.browserbot.getCurrentWindow());"

  selenium.drag_and_drop_to_object(drag_name, drop_name)

  arrow = "xpath=//div[@id='line_todo_#{drop_id}']/div/a[@class='show_successors']/img"
  selenium.wait_for_element(arrow)
end

When /^I expand the dependencies of "([^\"]*)"$/ do |todo_name|
  todo = Todo.find_by_description(todo_name)
  todo.should_not be_nil

  expand_img_locator = "xpath=//div[@id='line_todo_#{todo.id}']/div/a[@class='show_successors']/img"
  selenium.click(expand_img_locator)
end

Then /^I should see ([0-9]+) todos$/ do |count|
  count.to_i.downto 1 do |i|
    match_xpath "div["
  end
end

Then /^the dependencies of "(.*)" should include "(.*)"$/ do |child_name, parent_name|
  parent = @current_user.todos.find_by_description(parent_name)
  parent.should_not be_nil
  
  child = parent.pending_successors.find_by_description(child_name)
  child.should_not be_nil
end

Then /^I should see "([^\"]*)" within the dependencies of "([^\"]*)"$/ do |successor_description, todo_description|
  todo = @current_user.todos.find_by_description(todo_description)
  todo.should_not be_nil
  successor = @current_user.todos.find_by_description(successor_description)
  successor.should_not be_nil

  # argh, webrat on selenium does not support within, so this won't work
  # xpath = "//div[@id='line_todo_#{todo.id}'"
  # Then "I should see \"#{successor_description}\" within \"xpath=#{xpath}\""

  # let selenium look for the presence of the successor
  xpath = "xpath=//div[@id='line_todo_#{todo.id}']//div[@id='successor_line_todo_#{successor.id}']//span"
  selenium.wait_for_element(xpath, :timeout_in_seconds => 5)
end
