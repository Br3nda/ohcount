require File.dirname(__FILE__) + '/../../test_helper'

class Ohcount::ClearsilverTemplateTest < Ohcount::Test

	def test_comment
		html_lb = Ohcount::LanguageBreakdown.new("html", "<?cs\n?>", "", 0)
		clearsilver_template_lb = Ohcount::LanguageBreakdown.new("clearsilver", "", "#comment\n", 0)
		assert_equal [html_lb, clearsilver_template_lb], Ohcount::parse("<?cs\n #comment\n?>", "clearsilver_template")
	end

	def test_comprehensive
		verify_parse("clearsilver_template1.cs")
	end

	def test_comment_entities
		assert_equal('<!--comment-->', entities_array(" <!--comment-->", 'clearsilver_template', :comment).first)
		assert_equal('#comment', entities_array("<?cs\n#comment\n?>", 'clearsilver_template', :comment).first)
	end

end
