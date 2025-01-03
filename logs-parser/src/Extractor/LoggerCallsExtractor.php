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

namespace PrestaShop\SeamlessUpgradeToolbox\LogsParser\Extractor;

use Doctrine\Common\Collections\ArrayCollection;
use PhpParser\NodeTraverser;
use PhpParser\Parser;
use PhpParser\ParserFactory;
use PrestaShop\SeamlessUpgradeToolbox\LogsParser\Finder\PhpFinder;
use PrestaShop\SeamlessUpgradeToolbox\LogsParser\Traverser\LoggerTraverser;
use Symfony\Component\Finder\SplFileInfo;

class LoggerCallsExtractor
{
    protected Parser $parser;

    public function __construct(
        protected string $directory,
        protected PhpFinder $finder = new PhpFinder(),
    ) {
        $this->parser = (new ParserFactory())->createForHostVersion();
    }

    /**
     * @return array{string, string, string, string}
     */
    public function getCallsToLogger(): array
    {
        $logs = [];
        $files = $this->finder->getFiles($this->directory);

        foreach ($files as $file) {
            $logs = array_merge($logs, $this->extractFromFile($file));
        }

        return $logs;
    }

    /**
     * @return array{string, string, string, string}
     */
    protected function extractFromFile(SplFileInfo $file): array
    {
        $resultsCollection = new ArrayCollection();
        $ast = $this->parser->parse(file_get_contents($file->getRealPath()));

        $traverser = new NodeTraverser();
        $traverser->addVisitor(new LoggerTraverser($resultsCollection, $file));

        $traverser->traverse($ast);

        return $resultsCollection->toArray();
    }
}
