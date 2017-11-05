clear all
clc
close all

define_seed= 164;
%Runs MAB script with seed values specified.
for ds = 1:length(define_seed)
    rundriver(define_seed(ds));
end