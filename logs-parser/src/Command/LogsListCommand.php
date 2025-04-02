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

namespace PrestaShop\SeamlessUpgradeToolbox\LogsParser\Command;

use PrestaShop\SeamlessUpgradeToolbox\LogsParser\Extractor\LoggerCallsExtractor;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Helper\Table;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class LogsListCommand extends Command
{
    /** @var string */
    protected static $defaultName = 'list';

    protected function configure(): void
    {
        $this
            ->setName(self::$defaultName)
            ->setDescription('List calls to logger.')
            ->setHelp('Retrieve all the calls to the logger, useful for wording and criticity review.')
            ->addArgument('module-dir', InputArgument::REQUIRED, 'The path to the module to scan');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        /** @var string $moduleDir */
        $moduleDir = $input->getArgument('module-dir');
        $loggerCalls = (new LoggerCallsExtractor($moduleDir))->getCallsToLogger();

        $table = new Table($output);
        $table
            ->setHeaders(['Position', 'Criticity', 'Translated', 'Contents'])
            ->setRows($loggerCalls);

        $table->render();

        $output->writeln('');
        // TODO : Surprisingly high total of results
        $output->writeln(count($loggerCalls) . ' result(s) found.');

        return Command::SUCCESS;
    }
}
