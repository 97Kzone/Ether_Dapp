module.exports = async (promise) => {
    try {
        await promise;
        assert.fail('expected revert not received');
    } catch (error) {
        const revertFound = error.message.search('revert') >= 0;
        assert(revertFound, `Expected "revert", got ${error} instead`)
    }
}