1;

source('neuralNetwork/nn_learningCurves.m');
source('neuralNetwork/nn_adjustment.m');
source('neuralNetwork/graphics.m');
source('extra/fmincg.m');
source('extra/sigmoidFunction.m');
source('extra/sigmoidDerivative.m');
warning('off');

% Main function of the logistic regression analysis
function [Theta1,Theta2] = neuralNetwork(posExamples,negExamples,lCurves)
	num_inputs = columns(posExamples)-1; % Number of nodes of the input layer
	%------------------------------------------------------------------------------
	% PARAMETERS
	normalize = false; % Normalize the data or not
	lambda = 10; % Regularization term (default)
	percentage_training = 0.5; % Training examples / Total examples
	adjustLambda = true; % Look for optimal lambda
	rand_weights_iterations = 10; % Number of iterations to calculate the best initial weight matrix
	learningFreq = 0.2; % Adjust the learning rate (for learning curves)
	
	% NEURAL NETWORK PARAMETERS
	num_hidden = 120; % Number of nodes of the hidden layer
	max_iterations = 1000; % Number of maximum iterations in the training of the neural network
	adjustNodes = true; % Look for the optimal number of hidden nodes
	
	% ADJUSTMENT PARAMETERS
	percentage_adjustment= 0.1; % Adjustment examples / Total examples
	lambdaValues = [0,5,50,100]; % Possible values for lambda
	hidden_nodes = [20:40:220]; % Possible number of nodes
	%------------------------------------------------------------------------------
	
	if(adjustNodes || adjustLambda)
		adjusting = true;
	else
		adjusting = false;
	end;
	
	% Distribution of the examples (Positive and negative examples are equally
	% distributed)
	
	% Number of features
	numFeatures = columns(posExamples);
	
	% Number of training examples
	n_tra_pos = fix(percentage_training * rows(posExamples));
	n_tra_neg =	fix(percentage_training * rows(negExamples));
	
	% Selection of training examples
	traExamples = [posExamples(1:n_tra_pos,:);negExamples(1:n_tra_neg,:)];
	
	% Permute the order of the training examples
	traExamples = traExamples(randperm(size(traExamples,1)),:);
	
	X_tra = traExamples(:,1:numFeatures-1);
	Y_tra = traExamples(:,numFeatures);
	
	if (adjusting)
		% Number of adjustment examples
		n_adj_pos = fix(percentage_adjustment * rows(posExamples));
		n_adj_neg =	fix(percentage_adjustment * rows(negExamples));
	
		% Number of validation examples
		n_val_pos = rows(posExamples) - (n_tra_pos + n_adj_pos);
		n_val_neg =	rows(negExamples) - (n_tra_neg + n_adj_neg);
	
		% Selection of adjustment examples
		adjExamples = [posExamples(n_tra_pos+1:n_tra_pos+n_adj_pos,:);
										 negExamples(n_tra_neg+1:n_tra_neg+n_adj_neg,:)];
	
		% Permute the order of the adjustment examples
		adjExamples = adjExamples(randperm(size(adjExamples,1)),:);
	
		X_adj = adjExamples(:,1:numFeatures-1);
	
		% Selection of validation examples
		valExamples = [posExamples(n_tra_pos+n_adj_pos+1:rows(posExamples),:); ...
				      negExamples(n_tra_neg+n_adj_neg+1:rows(negExamples),:)];
	
		% Permute the order of the validation examples
		valExamples = valExamples(randperm(size(valExamples,1)),:);
	
		if(normalize)
			X_adj = featureNormalize (X_adj);
		end
		Y_adj = adjExamples(:,numFeatures);
	else
		% Number of validation examples
		n_val_pos = rows(posExamples) - n_tra_pos;
		n_val_neg =	rows(negExamples) - n_tra_neg;
		valExamples = [posExamples(n_tra_pos+1:rows(posExamples),:);
		              negExamples(n_tra_neg+1:rows(negExamples),:)];
	
		 % Permute the order of the validation examples
		 valExamples = valExamples(randperm(size(valExamples,1)),:);
	end

	X_val = valExamples(:,1:numFeatures-1);
	Y_val = valExamples(:,numFeatures);

	if(normalize)
			X_tra = featureNormalize (X_tra);
			X_val = featureNormalize (X_val);
	end
	
	if(adjustNodes) % Adjustment(Search of optimal number of hidden nodes)
		[bestNodes,errorAdj] = nn_adjustNodes (X_tra,Y_tra,X_adj,Y_adj, ...
		                                       num_inputs,lambda,hidden_nodes);
		num_hidden = bestNodes;
	end;
	
	%Initialization of the weight matrix with values that produces the minimum cost
	[initial_params_nn] = nn_initParams(X_tra,Y_tra,num_inputs, num_hidden, ...
	                                    lambda,rand_weights_iterations);
	
	% Adjustment process(Search of optimal lambda)
	if (adjustLambda)
		[bestLambda, errorAdj] = nn_adjustLambda(X_tra, Y_tra, X_adj, Y_adj, ...
		                                         initial_params_nn,num_inputs, num_hidden,lambdaValues);
		lambda = bestLambda;
	end;
	
	if (lCurves) % Learning Curves plus training
		learningFreq = fix(rows(X_tra) * learningFreq);
		[errTraining, errValidation, Theta1, Theta2] = nn_learningCurves (X_tra, ...
		Y_tra,X_val,Y_val,num_inputs, num_hidden,lambda,initial_params_nn,learningFreq,max_iterations);
	
		% Save/Load the result in disk (For debugging/speed up)
		%save learningCurves.tmp errTraining errValidation Theta1 Theta2;
		%load learningCurves.tmp
	
		%Show the graphics of the learning curves
		G_nn_LearningCurves(X_tra,errTraining, errValidation,learningFreq);
	else % Only Training
		printf('Training...\n');
		fflush(stdout);
		[Theta1, Theta2] = nn_training (X_tra,Y_tra,num_inputs, num_hidden, 1, ... 
		                                lambda,initial_params_nn,max_iterations);
	end
	
	% Report of the training:
	printf('\nNEURAL NETWORK REPORT\n')
	printf('-------------------------------------------------------------------:\n')
	% Distribution
	printf('DISTRIBUTION:\n')
	printf('Training examples %d (%d%%)\n',rows(X_tra),percentage_training*100);
	if (adjusting)
		printf('Adjustment examples %d (%d%%)\n',rows(X_adj),percentage_adjustment*100);
		printf('Validation examples %d (%d%%)\n',rows(X_val),((1-(percentage_training +
		percentage_adjustment))*100));
	else
		printf('Validation examples %d (%d%%)\n',rows(X_val),(1-percentage_training)*100);
	end;
	if(adjusting)
		printf('-------------------------------------------------------------------:\n')
		% Adjustment results
		printf('ADJUSTMENT ANALYSIS\n')
		if(adjustLambda)
			printf('Best value for lambda: %3.2f\n',bestLambda);
			printf('Error of the adjustment examples for the best lambda: %3.4f\n',errorAdj);
		end;
		if(adjustNodes)
			printf('Best number of hidden nodes: %i\n',bestNodes);
			printf('Error of the adjustment examples for the best number of nodes: %3.4f\n',errorAdj);
		end;
	end
	printf('-------------------------------------------------------------------:\n')
	% Error results
	printf('ERROR ANALYSIS:\n')
	
	params_nn = [Theta1(:); Theta2(:)];
	tra_error = nn_getError(X_tra, Y_tra, Theta1, Theta2,params_nn, num_inputs,	num_hidden);
	printf('Error in training examples: %f\n',tra_error);
	val_error = nn_getError(X_val, Y_val, Theta1, Theta2,params_nn, num_inputs,	num_hidden);
	printf('Error in validation examples: %f\n',val_error);
	printf('Error difference: %f\n',val_error - tra_error);
	printf('-------------------------------------------------------------------:\n')
	
	[opt_threshold,precision,recall,fscore] = nn_optRP(X_val, Y_val,Theta1,Theta2);
	printf('PRECISION/RECALL RESULTS (BEST F-SCORE):\n')
	printf('Optimum threshold: %f\n',opt_threshold);
	printf('Precision: %f\n',precision);
	printf('Recall: %f\n',recall);
	printf('Fscore: %f\n',fscore);
	printf('-------------------------------------------------------------------:\n')
	
	[opt_threshold,hits] = nn_optAccuracy(X_val, Y_val,Theta1,Theta2);
	printf('ACCURACY RESULTS (BEST ACCURACY)\n')
	printf('Optimum threshold: %f\n',opt_threshold);
	printf('Number of hits %d of %d\n',hits,rows(X_val));
	printf('Percentage of accuracy: %3.2f%%\n',(hits/rows(X_val))*100);
	printf('-------------------------------------------------------------------:\n')
end

%==============================================================================

% Training function
function [Theta1, Theta2,cost] = nn_training (X,y,num_inputs, num_hidden, ...
	num_labels, lambda,initial_params_nn,max_iterations)

	options = optimset('GradObj', 'on', 'MaxIter', max_iterations);
	[params_nn,cost] = fmincg (@(t)(nn_costFunction(t , num_inputs, num_hidden, ...
		num_labels, X, y , lambda)) , initial_params_nn , options);

	% Unroll the resulting theta vector into matrices

	Theta1 = reshape (params_nn (1:num_hidden * (num_inputs + 1)), num_hidden, (num_inputs + 1));
	
	Theta2 = reshape (params_nn ((1 + ( num_hidden * (num_inputs + 1))): end ), num_labels ,( num_hidden + 1 ));
	
	cost = cost(rows(cost));
end

%==============================================================================

% nn_costFunction calculates the cost and the gradient of a neural network of
% two layers
function [J, grad] = nn_costFunction (params_nn, num_inputs, num_hidden, num_labels, X, y,lambda)
	warning ('off');
	
	m = length(X(:,1));
	
	% Reshape params_nn back into the the weight matrices for our 2-layer neural network
	Theta1 = reshape (params_nn (1:num_hidden * (num_inputs + 1)), num_hidden, (num_inputs + 1));
	
	Theta2 = reshape (params_nn ((1 + ( num_hidden * (num_inputs + 1))): end ), num_labels ,( num_hidden + 1 ));
	
	% Initialize the variables
	J = 0;
	Theta1_grad = zeros(size(Theta1));
	Theta2_grad = zeros(size(Theta2));
	
	% Forward Propagation
	
	a1 = [ones(rows(X), 1), X];
	z2 = (Theta1 * a1');
	a2 = sigmoidFunction(z2);
	
	a2 = [ones(1, columns(a2)); a2];
	z3 = Theta2 * a2;
	a3 = sigmoidFunction(z3);
	
	% Initializes and gives values to the yk matrix (num_labels * m)
	
	yk = zeros(num_labels, m);
	for i= 1 :m
		yk(:,i) = (y(i)==[1:num_labels]');
	end
	
	% Calculate the cost
	
	J = (1 / m) * sum(sum((-1 * yk).*(log(a3)) - (1-yk).*(log(1-a3))));
	
	% Regularization of the cost
	
	Theta1_trim = Theta1(:, 2:columns(Theta1));
	Theta2_trim = Theta2(:, 2:columns(Theta2));
	
	regulation_theta1 = sum(sum(Theta1_trim.*Theta1_trim));
	regulation_theta2 = sum(sum(Theta2_trim.*Theta2_trim));
	
	J = J + (regulation_theta1 + regulation_theta2)*lambda/(2*m);
	
	% Backpropagation
	
	d3 = (a3-yk);
	%d2 = a2.*(1-a2).*(Theta2'*d3);
	d2 = (Theta2'*d3) .* sigmoidDerivative(z2);
	
	D2 = zeros(size(Theta2));
	D1 = zeros(size(Theta1));
	
	% Backpropagation algorithm
	for i=1:m
		D2 = D2 + d3(:,i)*(a2(:,i))';
	
		d2mod = d2(:,i);
		d2mod = d2mod(2:size(d2,1));
		D1 = D1 + d2mod * (a1(i,:));
	end
	
	% Regularization of the gradient
	Theta1_grad = (D1./m) + ((lambda/m) .* [zeros( num_hidden, 1 ), Theta1(:,2:columns(Theta1))]);
	Theta2_grad = (D2./m) + ((lambda/m) .* [zeros( num_labels, 1 ), Theta2(:,2:columns(Theta2))]);
	
	% Unroll gradients
	grad = [Theta1_grad(:) ; Theta2_grad(:)];
end

%==============================================================================

% Initializes a matrix with random values given its dimensions
function weightMatrix = randomWeights (L_in, L_out)
	INIT_EPSILON = sqrt(6) / sqrt(L_in + L_out);
	
	weightMatrix = rand(L_in, 1 + L_out) * (2 * INIT_EPSILON) - INIT_EPSILON;
end

%==============================================================================

% Function that selects the best initial weight matrix for the neural network training
function [initial_params_nn] = nn_initParams(X_tra,Y_tra,num_inputs, num_hidden,lambda,rand_weights_iterations);
	printf('Calculating initial weights...\n');
	max_iterations=15;
	Theta1 = randomWeights (num_hidden,num_inputs);
	Theta2 = randomWeights (1,num_hidden);
	initial_params_nn = [Theta1(:); Theta2(:)];
	[Theta1_aux,Theta2_aux,cost] = nn_training (X_tra,Y_tra,num_inputs, num_hidden, 1, lambda,initial_params_nn,max_iterations);
	
	for i = 1:rand_weights_iterations-1
		Theta1_aux = randomWeights (num_hidden,num_inputs);
		Theta2_aux = randomWeights (1,num_hidden);
		initial_params_nn_aux = [Theta1_aux(:); Theta2_aux(:)];
	
		[Theta1_aux,Theta2_aux,newCost] = nn_training (X_tra,Y_tra,num_inputs, num_hidden, 1, lambda,initial_params_nn_aux,max_iterations);
	
		if (newCost < cost)
			Theta1 = Theta1_aux;
			Theta2 = Theta2_aux;
		end;
		fflush(stdout);
	
	end;
	% Roll the matrices in one initial vector
	initial_params_nn = [Theta1(:); Theta2(:)];
	
end

%==============================================================================

function [hypothesis] = nn_hFunction(X,Theta1,Theta2)
	a1 = [ones(rows(X), 1), X];
	z2 = (Theta1 * a1');
	a2 = sigmoidFunction(z2);
	
	a2 = [ones(1, columns(a2)); a2];
	z3 = Theta2 * a2;
	a3 = sigmoidFunction(z3);
	
	hypothesis = a3';
end

%==============================================================================

% Function to classify examples
function prediction = nn_prediction(X, Theta1, Theta2, threshold)
	prediction = nn_hFunction(X,Theta1, Theta2);
	prediction = prediction > threshold;
end

%==============================================================================

% Function to extract the precision and the recall of a trained model given a
% threshold
function [precision,recall,fscore] = nn_precisionRecall(X, y,Theta1, Theta2, ...
	threshold)
	% Get predicted y values
	pred_y = nn_prediction(X, Theta1, Theta2, threshold);

	% Precision calculation
	true_positives = sum(pred_y & y); %Logic AND to extract the predicted
										%positives that are true
	pred_positives = sum(pred_y);

	if(pred_positives != 0)
		precision = true_positives / pred_positives;
	else
		precision = 0;
	end

	%Recall calculation
	actual_positives = sum(y);
	test = [pred_y,y,pred_y&y];

	if(actual_positives != 0)
		recall = true_positives / actual_positives;
	else
		recall = 0;
	end

	fscore =  (2*precision*recall) / (precision + recall);
end

%==============================================================================

% Function to extract the optimum threshold that guarantees the best trade-off
% between precision and the recall of a trained model
function [opt_threshold,precision,recall,fscore] = nn_optRP(X, y,Theta1, Theta2)
	for i = 1:100 % Try values from 0.01 to 1 in intervals of 0.01
		[precisions(i),recalls(i),fscores(i)] = nn_precisionRecall(X, y,Theta1,
			Theta2,	i/100);
	end

	% Select the best F-score and the threshold associated to it
	[max_Fscore, idx] = max(fscores);
	opt_threshold = (idx)/100;
	precision = precisions(idx);
	recall = recalls(idx);
	fscore = fscores(idx);
	[max_prec, idx_max_prec] = max(precisions);

	% Show the graphics of the recall-precision results
	G_nn_RecallPrecision(recalls,precisions,opt_threshold);
end

%==============================================================================

% Function to extract the optimum threshold that guarantees the maximum number
% of hits given a trained model over a set of examples
function [opt_threshold,max_hits] = nn_optAccuracy(X, y,Theta1,Theta2)
	for i = 1:100 % Try values from 0.01 to 1 in intervals of 0.01
		[hits(i)] = sum(nn_prediction(X, Theta1, Theta2, i/100) == y);
	end

	% Select the best F-score and the threshold associated to it
	[max_hits, idx] = max(hits);
	opt_threshold = (idx)/100;

	% Show the graphics of the recall-precision results
	G_nn_Accuracy(hits,opt_threshold,rows(X));
end

%==============================================================================

% Function to calculate the error produced by Theta1,Theta2 over a set of examples
function error = nn_getError(X, y, Theta1, Theta2,params_nn, num_inputs, num_hidden)
	error = nn_costFunction(params_nn, num_inputs, num_hidden, 1,X, y,0);
end
