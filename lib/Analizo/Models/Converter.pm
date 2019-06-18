package Analizo::Models::Converter;

use File::Basename;
our $AUTOLOAD;


# Returns undef for any method called here that 
sub AUTOLOAD {
  return if $AUTOLOAD =~ /::DESTROY$/;

  return undef;
}

sub _file_to_module {
  my ($self, $filename) = @_;
  $filename =~ s/\.r\d+\.expand$//;
  return basename($filename);
}

sub _function_to_module {
  my ($self, $model, $function) = @_;
  return undef if !exists($model->members->{$function});
  return $self->_file_to_module($model->members->{$function});
}

sub _function_to_file {
  my ($self, $model, $function) = @_;
  return unless exists $model->members->{$function};
  my $module = $model->members->{$function};
  $model->{files}->{$module};
}

1;