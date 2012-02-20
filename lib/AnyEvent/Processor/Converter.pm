package AnyEvent::Processor::Converter;
# ABSTRACT: Role for any converter class

use Moose::Role;

=method convert

=cut

requires 'convert';

1;

