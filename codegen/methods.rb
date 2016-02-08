#!/usr/bin/env ruby

require 'nokogiri'
require 'active_support/inflector'
require 'erb'
require 'pathname'

def type_for_domain(xml, domain)
  domain = xml.xpath("/amqp/domain[@name='#{domain}']").first
  if domain
    domain[:type]
  else
    ""
  end
end

def from_this_dir(path)
  File.absolute_path(path, __dir__)
end

def colon_aligned_name(first_line, name)
  to_colon, _ = first_line.split(':')
  "#{name}:".rjust(to_colon.length + 1)
end

def property_type_and_label(field)
  "(nonnull #{field[:type]} *)#{field[:name]}"
end

def outgoing?(method)
  method.xpath('chassis').first[:name] == 'server'
end

File.open(from_this_dir("amqp0-9-1.extended.xml")) do |f|
  xml = Nokogiri::XML(f)
  template = ERB.new(File.read(from_this_dir('template.erb')), nil, '-')

  puts <<-OBJC
// This file is generated. Do not edit.
#import <Foundation/Foundation.h>
@import Mantle;
#import "AMQProtocolValues.h"

  OBJC

  xml.xpath("/amqp/class").each do |klass|
    class_name = klass[:name].capitalize
    klass.xpath("method").each do |method|
      method_name = method[:name].underscore.classify
      fields = method.xpath('field').map { |f|
        type = if f[:domain]
                 type_for_domain(xml, f[:domain]).underscore.camelize
               else
                 f[:type].underscore.camelize
               end
        {
          type: "AMQ#{type}",
          name: f[:name].underscore.camelize(:lower),
        }
      }

      constructor =
        if outgoing?(method) && fields.any?
          first_field_name = "#{fields[0][:name][0].upcase}#{fields[0][:name][1..-1]}:"
          first_line = "- (nonnull instancetype)initWith#{first_field_name}#{property_type_and_label(fields[0])}"
          constructor_rest = fields[1..-1].map { |field|
            "#{colon_aligned_name(first_line, field[:name])}#{property_type_and_label(field)}"
          }
          "#{([first_line] + constructor_rest).join("\n")};"
        end

      protocol = outgoing?(method) ? "AMQOutgoing" : "AMQIncoming"

      puts template.result(binding)
    end
  end
end
