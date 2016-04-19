/*******************************************************************************
 * Copyright (c) 2015 Dell Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Daniel Ford, Dell Corporation - initial API and implementation
 *******************************************************************************/
package com.dell.research.bc.eth.solidity.editor.ui.contentassist

import com.dell.research.bc.eth.solidity.editor.ui.contentassist.AbstractSolidityProposalProvider
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor

import com.dell.research.bc.eth.solidity.editor.SolidityUtil;

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class SolidityProposalProvider extends AbstractSolidityProposalProvider {
	
	override completeMessage_Field(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		SolidityUtil.MESSAGE_MEMBERS.forEach[
		acceptor.accept(
				createCompletionProposal(it, it,
					null, context));
		]
	}
	
	override completeCurrentBlock_Field(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		SolidityUtil.CURRENTBLOCK_MEMBERS.forEach[
		acceptor.accept(
				createCompletionProposal(it, it,
					null, context));
		]
	}
	
	override completeTransaction_Field(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		SolidityUtil.TRANSACTION_MEMBERS.forEach[
		acceptor.accept(
				createCompletionProposal(it, it,
					null, context));
		]
	}
	
}
