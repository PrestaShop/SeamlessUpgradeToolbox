<?php

/**
 * Copyright since 2007 PrestaShop SA and Contributors
 * PrestaShop is an International Registered Trademark & Property of PrestaShop SA
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Academic Free License 3.0 (AFL-3.0)
 * that is bundled with this package in the file LICENSE.md.
 * It is also available through the world-wide-web at this URL:
 * https://opensource.org/licenses/AFL-3.0
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@prestashop.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade PrestaShop to newer
 * versions in the future. If you wish to customize PrestaShop for your
 * needs please refer to https://devdocs.prestashop.com/ for more information.
 *
 * @author    PrestaShop SA and Contributors <contact@prestashop.com>
 * @copyright Since 2007 PrestaShop SA and Contributors
 * @license   https://opensource.org/licenses/AFL-3.0 Academic Free License 3.0 (AFL-3.0)
 */

namespace PrestaShop\SeamlessUpgradeToolbox\LogsParser\Traverser;

use Doctrine\Common\Collections\ArrayCollection;
use PhpParser\Node;
use PhpParser\Node\Expr\ArrayDimFetch;
use PhpParser\Node\Expr\BinaryOp\Concat;
use PhpParser\Node\Expr\CallLike;
use PhpParser\Node\Expr\FuncCall;
use PhpParser\Node\Expr\MethodCall;
use PhpParser\Node\Expr\Variable;
use PhpParser\NodeVisitorAbstract;
use Symfony\Component\Finder\SplFileInfo;

class LoggerTraverser extends NodeVisitorAbstract
{
    public const LOGGER_METHODS = ['emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'info', 'debug'];
    public const TRANSLATION_METHODS = ['trans'];

    /** @param ArrayCollection<string, array{string, string, string, string}> $results */
    public function __construct(
        protected ArrayCollection $results,
        protected SplFileInfo $file,
    ) {
    }

    public function leaveNode(Node $node)
    {
        $this->results->add($this->getOccurences($node));
    }

    protected function getOccurences(Node $node): array
    {
        if (!$this->appliesFor($node)) {
            return [];
        }

        /** @var CallLike $node */
        $nodeName = $this->getNodeName($node);

        if (!in_array($nodeName, self::LOGGER_METHODS)) {
            return [];
        }

        $loggedNode = $this->getTranslationNodeOrNull($node) ?? $node;

        return [
            $this->file->getRelativePathname() . ':' . $node->getAttribute('startLine'),
            $nodeName,
            $loggedNode !== $node ? 'Yes' : 'No',
            $this->getValue($loggedNode->getArgs()[0]),
        ];
    }

    /**
     * @return bool
     */
    private function appliesFor(Node $node)
    {
        if (empty($node->args)) {
            return false;
        }

        return
            ($node instanceof MethodCall || $node instanceof FuncCall)
            && ($node->name instanceof Node\Identifier || $node->name instanceof Node\Name)
        ;
    }

    /**
     * @return string
     */
    private function getValue(Node $node)
    {
        // Nodes may or may not have the value
        if (!empty($node->value)) {
            $node = $node->value;
        }

        if (gettype($node) === 'string') {
            return $node;
        }

        if ($node instanceof Node\Scalar\String_) {
            return $node->value;
        }

        if ($node instanceof Variable) {
            return '$' . $node->name;
        }

        if ($node instanceof MethodCall) {
            return '$' . $this->getNodeName($node->var) . '->' . $this->getNodeName($node->name) . '()';
        }

        if ($node instanceof FuncCall) {
            return $this->getNodeName($node->name) . '(' . implode(', ', array_map([$this, 'getValue'], $node->args)) . ')';
        }

        if ($node instanceof ArrayDimFetch) {
            return $this->getValue($node->var) . '[' . $this->getValue($node->dim) . ']';
        }

        if ($node instanceof Concat) {
            return $this->getValue($node->left) . ' . ' . $this->getValue($node->right);
        }

        return $this->getNodeName($node) ?? '???';
    }

    /**
     * @param MethodCall|FuncCall $node
     */
    private function getNodeName(Node $node): ?string
    {
        if (empty($node->name)) {
            return null;
        }

        if (gettype($node->name) === 'string') {
            return $node->name;
        }

        return $node->name->name;
    }

    private function getTranslationNodeOrNull(CallLike $node): ?CallLike
    {
        foreach ($node->getRawArgs() as $arg) {
            $subNode = $arg->value;
            if (in_array($this->getNodeName($arg->value), self::TRANSLATION_METHODS)) {
                return $subNode;
            }
        }

        return null;
    }
}
