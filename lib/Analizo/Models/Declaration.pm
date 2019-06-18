package Analizo::Models::Declaration;

sub declare_variable {
  my ($self, $model, $module, $variable) = @_;
  $model->declare_member($module, $variable, 'variable');

  if (!exists($model->{modules}->{$module})){
    $model->{modules}->{$module} = {};
    $model->{modules}->{$module}->{variables} = [];
  }
  if(! grep { $_ eq $variable } @{$model->{modules}->{$module}->{variables}}){
    push @{$model->{modules}->{$module}->{variables}}, $variable;
  }
}

sub declare_member {
  my ($self, $model, $module, $member, $type) = @_;

  # mapping member to module
  $model->{members}->{$member} = $module;
}

sub declare_function {
  my ($self, $model, $module, $function) = @_;
  return unless $module;
  $model->declare_member($module, $function, 'function');

  if (!exists($model->{modules}->{$module})){
    $model->{modules}->{$module} = {};
    $model->{modules}->{$module}->{functions} = [];
  }
  if(! grep { $_ eq $function } @{$model->{modules}->{$module}->{functions}}){
    push @{$model->{modules}->{$module}->{functions}}, $function;
  }
}

sub declare_module {
  my ($self, $model, $module, $file) = @_;
  if (! grep { $_ eq $module} @{$model->{module_names}}) {
    push @{$model->{module_names}}, $module;
  }
  if (defined($file)) {
    #undup filename
    foreach (@{$model->{files}->{$module}}) {
      return if($_ eq $file);
    }

    $model->{files}->{$module} ||= [];
    push(@{$model->{files}->{$module}}, $file);

    $model->{module_by_file}->{$file} ||= [];
    push @{$model->{module_by_file}->{$file}}, $module;
  }
}

1;