function svm_G_adjustment(values,FscoreMatrix)
	figure;
	surf(values, values, FscoreMatrix);
	xlabel('Values for C');
	ylabel('Values for sigma');
	zlabel('Percentage of accuracy');
	title('Adjustment plot for SVM');
end