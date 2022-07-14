import itertools
import random
import unittest
import unittest.runner
import helper_module as hm


class CustomTextTestResult(unittest.runner.TextTestResult):

    def __init__(self, stream, descriptions, verbosity):
        self.test_numbers = itertools.count(1)
        return super(CustomTextTestResult, self).__init__(stream, descriptions, verbosity)

    def startTest(self, test):
        if self.showAll:
            progress = '[{0}/{1}] '.format(next(self.test_numbers), self.test_case_count)
            self.stream.write(progress)
            test.progress_index = progress
        return super(CustomTextTestResult, self).startTest(test)

    def _exc_info_to_string(self, err, test):
        info = super(CustomTextTestResult, self)._exc_info_to_string(err, test)
        if self.showAll:
            info = 'Test number: {index}\n{info}'.format(
                index=test.progress_index,
                info=info
            )
        return info


class CustomTextTestRunner(unittest.runner.TextTestRunner):
    resultclass = CustomTextTestResult

    def run(self, test):
        self.test_case_count = test.countTestCases()
        return super(CustomTextTestRunner, self).run(test)

    def _makeResult(self):
        result = super(CustomTextTestRunner, self)._makeResult()
        result.test_case_count = self.test_case_count
        return result


class TestSimomSays(unittest.TestCase):

    def round_generation(self):
        for _ in range (250):
            for accuracy in range (1, 4):
                round = hm.generate_round(1, accuracy)
                if accuracy == 1:
                    self.assertTrue(round >= 1 and round <= 9)
                elif accuracy == 2:
                    self.assertTrue(round >= 1 and round <= 36)
                elif accuracy == 3:
                    self.assertTrue(round >= 1 and round <= 144)

    def ml_model_quad(self):
        hm.load_models_and_databases()
        data = hm.load_scaler(1)
        average_accuracy = 0.0
        print("\n\nAverage accuracy >= 90% to pass...\n")
        for i in range (3):
            count = 0
            for _ in range (50):
                round = hm.generate_round(1)
                filtered = data.loc[data['144'] == round]
                filtered.pop(filtered.columns[-1])
                datapoint = filtered.values[random.randint(0, len(filtered)-1)]
                predicted = hm.predict(datapoint, 1)
                if predicted == round:
                    count += 1
            accuracy = count / 50 * 100
            print(f"\tAccuracy {i+1}/3 = {accuracy}%")
            average_accuracy += accuracy
        average_accuracy /= 3
        print(f"\n\tAverage accuracy {average_accuracy}%")
        self.assertTrue((average_accuracy) >= 90.0)

    def ml_model_square(self):
        data = hm.load_scaler(2)
        average_accuracy = 0.0
        print("\n\nAverage accuracy >= 90% to pass...\n")
        for i in range (3):
            count = 0
            for _ in range (50):
                round = hm.generate_round(2)
                filtered = data.loc[data['144'] == round]
                filtered.pop(filtered.columns[-1])
                datapoint = filtered.values[random.randint(0, len(filtered)-1)]
                predicted = hm.predict(datapoint, 2)
                if predicted == round:
                    count += 1
            accuracy = count / 50 * 100
            print(f"\tAccuracy {i+1}/3 = {accuracy}%")
            average_accuracy += accuracy
        average_accuracy /= 3
        print(f"\n\tAverage accuracy {average_accuracy}%")
        self.assertTrue((average_accuracy) >= 90.0)

    def ml_model_led(self):
        data = hm.load_scaler(3)
        average_accuracy = 0.0
        print("\n\nAverage accuracy >= 90% to pass...\n")
        for i in range (3):
            count = 0
            for _ in range (50):
                round = hm.generate_round(3)
                filtered = data.loc[data['144'] == round]
                filtered.pop(filtered.columns[-1])
                datapoint = filtered.values[random.randint(0, len(filtered)-1)]
                predicted = hm.predict(datapoint, 3)
                if predicted == round:
                    count += 1
            accuracy = count / 50 * 100
            print(f"\tAccuracy {i+1}/3 = {accuracy}%")
            average_accuracy += accuracy
        average_accuracy /= 3
        print(f"\n\tAverage accuracy {average_accuracy}%")
        self.assertTrue((average_accuracy) >= 90.0)

def get_tests():
    test_functions = ['round_generation', 'ml_model_quad', 'ml_model_square', 'ml_model_led']
    return [TestSimomSays(function) for function in test_functions]


if __name__ == '__main__':
    print("\nPOC Unit Tests\n")
    
    test_suite = unittest.TestSuite()
    tests = get_tests()
    test_suite.addTests(tests)
    CustomTextTestRunner(verbosity=2).run(test_suite)