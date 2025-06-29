// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ICronUpkeep {
    // EVENTS
    event CronJobExecuted(uint256 indexed id, bool success);
    event CronJobCreated(uint256 indexed id, address target, bytes handler);
    event CronJobUpdated(uint256 indexed id, address target, bytes handler);
    event CronJobDeleted(uint256 indexed id);

    // ERRORS
    error CronJobIDNotFound(uint256 id);
    error ExceedsMaxJobs();
    error InvalidHandler();
    error TickInFuture();
    error TickTooOld();
    error TickDoesntMatchSpec();

    // FUNCTIONS

    /**
     * @notice Creates a cron job from the given encoded spec
     * @param target the destination contract of a cron job
     * @param handler the function signature on the target contract to call
     * @param encodedCronSpec abi encoding of a cron spec
     */
    function createCronJobFromEncodedSpec(
        address target,
        bytes calldata handler,
        bytes calldata encodedCronSpec
    ) external;

    /**
     * @notice Updates a cron job from the given encoded spec
     * @param id the id of the cron job to update
     * @param newTarget the destination contract of a cron job
     * @param newHandler the function signature on the target contract to call
     * @param newEncodedCronSpec abi encoding of a cron spec
     */
    function updateCronJob(
        uint256 id,
        address newTarget,
        bytes calldata newHandler,
        bytes calldata newEncodedCronSpec
    ) external;

    /**
     * @notice Deletes the cron job matching the provided id
     * @param id the id of the cron job to delete
     */
    function deleteCronJob(uint256 id) external;

    /**
     * @notice gets a list of active cron job IDs
     * @return list of active cron job IDs
     */
    function getActiveCronJobIDs() external view returns (uint256[] memory);

    /**
     * @notice gets a cron job
     * @param id the cron job ID
     * @return target - the address a cron job forwards the eth tx to
     *         handler - the encoded function sig to execute when forwarding a tx
     *         cronString - the string representing the cron job
     *         nextTick - the timestamp of the next time the cron job will run
     */
    function getCronJob(
        uint256 id
    )
        external
        view
        returns (
            address target,
            bytes memory handler,
            string memory cronString,
            uint256 nextTick
        );
}
