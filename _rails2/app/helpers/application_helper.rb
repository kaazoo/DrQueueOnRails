# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def vm_type_name(type)
    case type
      when "t1.micro":
        return "Mini"
      when "m1.large":
        return "Large"
      when "m1.xlarge":
        return "Extra Large (RAM)"
      when "c1.xlarge":
        return "Extra Large (Cores)"
    end
  end

end
