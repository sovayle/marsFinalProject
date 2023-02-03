.data

# USE CASE 1
	#Motion/Heat sensing
detectionMsg:		.asciiz "\nMovement has been detected\n"
heatEnabledMsg:	.asciiz "\nEnabling heat detection sequence..\n"
promptSecMsg:		.asciiz "\nKey in seconds : "
seconds:		.space 1 
tempMsg:		.asciiz "\nSeconds > 5"
temperatureMsg:	.asciiz "\nKey in temperature : "
exitMsg:		.asciiz "\nProgram Exited"
tempErrorMsg:		.asciiz "\nTemperature is not normal"
tempNormalMsg:		.asciiz "\nNormal Temperature"
notifyMsg:		.asciiz"\nNotifying user..\n\nUser Notified."

#USE CASE 2 & 3
	## A speaker and screen display instructions (get info from sender for verification)
	# reason for entry options: 
	# food - 1
	# parcel - 2
	# other - 3
	
	# if food enter 
	# if parcel, tracking number
	# if other, enter reasoning and wait for confirmation

		# Sender enter details through touchpad

		# verify

		# if verified, ..#opening mailbox


reasonsList:			.asciiz "\nThe following is a list of reasons:\n1)Food\n2)Parcel\n3)Other\n"
getReasoning:			.asciiz "\nPlease enter a number: "
wrongReasoningNumber:		.asciiz "\nWrong input.\nPlease enter a number between 1-3:"
getTrackingNumber:		.asciiz "\nPlease enter tracking number (13-14 characters):"
trackingNumber:		.space 15
verifyingDetails:		.asciiz "\nVerifiying delivery details...\n"
verified:			.asciiz "\nPackage verified!\nOpening mailbox..."
getOtherReasoning:		.asciiz  "You have chosen 3)Other.\nPlease enter details of package in less than 100 words:"
otherReasoning:		.space 101
verifyingOwner:		.asciiz "\nWaiting for owner to accept or reject details...\n"
wrongDetails:			.asciiz "you have entered wrong details"
#example tracking number: MY100, Food100


# USE CASE 4
	weightDetection: .asciiz "Please put in the parcel.\nCurrent weight: "
	closeWarning: .asciiz "The mailbox is closing, please keep your hands off the door\n"
	closeWarning2: .asciiz "No parcel detected, closing the door\n"
	waitTime: .asciiz "Current time: "
	parcelDelivered: .asciiz "Parcel succesfully delivered!"
	trackingNo:	.asciiz "MY100 "

.text

main:

la	$a0, detectionMsg	# movement detected
jal PrintString


la	$a0, heatEnabledMsg	# enabling heat detector
jal PrintString


la	$a0, promptSecMsg	# key in number of seconds message
jal PrintString


jal GetInt			# key in seconds
syscall
move	$s1, $v0

bgt	$s1, 5, nextStage	# if seconds > 5, go to NextStage
blt	$s1, 5, exit		# if seconds < 5, exit

nextStage:

	la	$a0, tempMsg	# 
	jal PrintString 

	
	la	$a0, temperatureMsg
	jal PrintString

	
	jal GetInt		# key in temperature
	syscall
	move	$s1, $v0
	
	bgt	$s1, 35, checkHigherTemp	# go to checkHigherTemo if temperature>35
	j tempError	# else go to tempError
	

checkHigherTemp:
	bgt	$s1, 40, tempError	# if temperature > 40, go to tempError
	
	
	la	$a0, tempNormalMsg	# display Normal msg
	jal PrintString

	j notifyUser		# jump to notifyUser
	

tempError:

	la	$a0, tempErrorMsg
	jal PrintString
	j exit

notifyUser:

	la	$a0, notifyMsg
	jal PrintString
	j usecase2

exit:

	la	$a0, exitMsg
	jal PrintString

	li	$v0, 10
	syscall








#USE CASE 2 Procedures


usecase2:
	la	$s6, 0x100112c4		#MY100	(Presaved tracking number by owner for his/her parcel)
	la	$s7, 8		#MY100	(Presaved tracking number by owner for his/her parcel)
			
	li	$v0, 4
	la	$a0, reasonsList	#Screen displays instruction for the sender. Speaker voice outs the instructions.
	syscall
	
	li	$v0, 4
	la	$a0, getReasoning	
	syscall

togetreason:
	li	$v0, 5			# Sender keys in reason number (1-3) getReasoning
	syscall
	addi	$s0,$v0,0 		#s0 contains reason number

#input validation 1
	blt 	$s0, 4,lessthan			#reason is less than 4
	la 	$a0, wrongReasoningNumber	#reason number is wrong. Speaker voice outs the error message.
	jal	PrintString
	j	togetreason
	
lessthan:
	bgt 	$s0,0 packageInfo		#reason is greater than 0
	la 	$a0, wrongReasoningNumber	#reason number is wrong. Speaker voice outs the error message.
	jal	PrintString
	j	togetreason
		

#input validation 2	
packageInfo:
	beq 	$s0, 3, other	#branch to other if reasoning is 3)other, else 			
	li	$v0, 4
	la	$a0, getTrackingNumber
	syscall
	
	li	$v0, 8			# Sender keys in tracking number of food/parcel
	syscall
	move $s5, $v0
	
	li	$v0, 4
	la	$a0, verifyingDetails	# Program verifies details based on database, Screen and speaker displays and voice message to sender.
	syscall
	
	beq 	$s5, $s7, go		#comparing sender's package details with details in database

	
	li	$v0, 4
	la	$a0, wrongDetails	#prompt wrong details message
	syscall
	j 	endprogram

go:
	li	$v0, 4
	la	$a0, verified
	syscall
	j 	unlock	# use case 4

other:
	li	$v0, 4
	la	$a0, getOtherReasoning	# Program prompts sender to enter package information.
	syscall
	
	li	$v0, 8			# Sender keys in reasoning
	la	$s4, otherReasoning
	li	$a1, 101
	syscall
	
	li	$v0, 4
	la	$a0, verifyingOwner	# Program waits for verification from owner
	
	beq 	$s4, $s7, go		#comparing sender's package details with details in database
	syscall
	
	li	$v0, 4
	la	$a0, wrongDetails	#prompt wrong details message
	syscall
	
	j	endprogram	

endprogram:
	li	$v0,10
	syscall


# Use case 4 procedures
unlock:
#Print out text to put in parcel in mailbox 
	la $a0, weightDetection
	jal PrintString

#The mailbox detects the weight of the parcel and closes
	jal GetInt	#The weight should be auto inputted by the weight sensor
	syscall
	move	$s7, $v0
	
	bgt	$s7, 50, closeMB	# if weight > 50g proceed to closeMB(close mailbox) 
	beq	$s7, 0, wait		# if weight = 0 proceed to wait

closeMB:
	la $a0,closeWarning
	jal PrintString
	j notifyUser2
	
wait:
	# if sensor stays 0kg for more than 30 secs the mailbox closes
	la $a0, waitTime
	jal PrintString
	
	jal GetInt #gets input from mailbox timer
	syscall
	move $t9, $v0
	
	la $a0, closeWarning2
	bgt $t9, 29, noWeight #closing mailbox after 30 secs of no weight sensed

	j unlock
	
notifyUser2:
	
	la 	$a0, trackingNo
	jal PrintString #To print the parcel tracking number, so that owner would know which parcel is delivered
	
	la $a0, parcelDelivered
	jal PrintString
	
	j exit

noWeight:
	
	jal PrintString
	j exit



#All basic procedures
PrintString:
li $v0,4
syscall
jr $ra


GetString:
li $v0,8
jr $ra

GetInt:
li $v0,5
jr $ra

GetFloat:
li $v0,6
jr $ra

PrintInt:
li $v0,1
jr $ra
